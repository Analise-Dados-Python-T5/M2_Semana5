-- =============================================================================
-- Desafio -- Etapa 3: SCD Tipo 1 -- corrigir o nome do estado
-- =============================================================================
-- A carga inicial (scripts/03_carga_inicial.py) gravou "Pernanbuco" em vez
-- de "Pernambuco" para a sigla PE (de propósito -- ver ERRO_DIGITACAO
-- naquele script) -- nas DUAS versões, 2010 e 2022, porque é o mesmo nome
-- errado se repetindo. É uma correção de cadastro, sem motivo para guardar
-- histórico: igual à Vitrine corrigindo a cidade da Laura Macedo
-- (sql/03_scd_tipo1_cliente.sql). Isso é SCD Tipo 1.
--

-- ANTES (2 linhas, 2010 e 2022, as duas com "Pernanbuco"):
SELECT sk_estado, sigla, nome_estado, ano_referencia FROM dw_populacao.dim_estado_scd2 WHERE sigla = 'PE';

-- INSERT ... SELECT ... ON CONFLICT
INSERT INTO dw_populacao.dim_estado_scd2 (
    id_estado, sigla, nome_estado, regiao, populacao, ano_referencia, data_inicio, data_fim, registro_atual
)
SELECT id_estado, sigla, 'Pernanbuco', regiao, populacao, ano_referencia, data_inicio, data_fim, registro_atual
FROM dw_populacao.dim_estado_scd2
WHERE sigla = 'PE'
ON CONFLICT (sigla, ano_referencia)                -- dispara quando a combinação sigla+ano já existe (as 2 linhas de PE)
DO UPDATE SET nome_estado = EXCLUDED.nome_estado; 

-- DEPOIS: as MESMAS 2 sk_estado, nome corrigido nas duas -- sem linha nova.
SELECT sk_estado, sigla, nome_estado, ano_referencia FROM dw_populacao.dim_estado_scd2 WHERE sigla = 'PE';

-- Rode com:
--   psql -h localhost -U postgres -d vitrine -f sql/01_scd_tipo1_correcao.sql
-- =============================================================================

-- TODO: SELECT "antes"

-- TODO: INSERT ... ON CONFLICT (sigla, ano_referencia) DO UPDATE ...

-- TODO: SELECT "depois"
