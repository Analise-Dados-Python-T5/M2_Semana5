"""
Desafio -- Etapa 5: carga incremental. A estimativa 2026 do IBGE chegou
(Etapa 4, o cenário) -- agora é hora de descobrir quais estados realmente
tiveram a população alterada, sem reprocessar os 27 de novo.

A Vitrine usa a Estratégia 1 do slide 36 (updated_at) porque a origem dela
(staging.vendas_raw) tem essa coluna. Aqui não existe um "updated_at" na
Wikipédia -- então usamos a Estratégia 3 do mesmo slide: comparar o valor
ATUAL (que já está em dw_populacao.dim_estado_scd2) com o valor NOVO (que
acabamos de raspar de novo). Só processamos o que realmente mudou.

Pré-requisitos, na ordem:
  1) sql/00_dw_populacao_schema.sql + scripts/03_carga_inicial.py (versões 2010 e 2022)
  2) sql/01_scd_tipo1_correcao.sql (nome do PE corrigido)

Rode com:  python3 scripts/04_carga_incremental.py
"""
import importlib.util
import os
from pathlib import Path

import pandas as pd
from dotenv import load_dotenv
from sqlalchemy import create_engine, text

ROOT = Path(__file__).resolve().parent.parent
load_dotenv(ROOT / ".env")
DB_PASSWORD = os.environ["DB_PASSWORD"]
CONEXAO_POSTGRES = f"postgresql+psycopg2://postgres:{DB_PASSWORD}@localhost:5432/ibge"
NOME_PIPELINE = "etl_populacao_brasil"
ANO_ESTIMATIVA = 2026

_spec = importlib.util.spec_from_file_location("transformar", ROOT / "scripts" / "02_transformar.py")
transformar = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(transformar)


def estados_com_populacao_alterada(df_unificado: pd.DataFrame, engine) -> pd.DataFrame:

   vigente = pd.read_sql(
      "SELECT sigla, populacao as populacao_vigente FROM dw_populacao.dim_estado_scd2 WHERE registro_atual = true",
      engine,
   )
   
   comparado = df_unificado.merge(vigente, on="sigla", how="left")
   alterados = comparado[comparado["populacao_2026"] != comparado["populacao_vigente"]]

   print (f"{len(alterados)} de {len(comparado)} estados tiveram a população alterada")
   return alterados[["id", "sigla", "nome", "regiao", "populacao_2026"]]


def avancar_controle(engine):
   with engine.begin() as conn:
      conn.execute(
         text("UPDATE dw_populacao.controle_etl SET ultima_carga = now() WHERE nome_pipeline = :nome"),
         {"nome": NOME_PIPELINE}
      )

if __name__ == "__main__":
    engine = create_engine(CONEXAO_POSTGRES)
    populacao_2010 = transformar.extrair_fontes.extrair_populacao_2010_csv()
    estados = transformar.extrair_fontes.extrair_estados_api()
    populacao = transformar.extrair_fontes.extrair_populacao_wikipedia()
    df_unificado = transformar.juntar_fontes(estados, populacao, populacao_2010)

    alterados = estados_com_populacao_alterada(df_unificado, engine)
    print(f"\n{len(alterados)} estado(s) com população alterada para {ANO_ESTIMATIVA}:")
    print(alterados[["sigla", "nome", "populacao_2026"]])
    print("\nAgora use esses estados em sql/02_scd_tipo2_populacao.sql "
          "(Etapa 6) para fechar a versão 2022 e abrir a versão 2026.")
