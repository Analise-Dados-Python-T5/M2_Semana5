-- =============================================================================
-- Desafio -- Etapa 6: SCD Tipo 2 -- fecha a versão 2022, abre a versão 2026
-- =============================================================================
-- A população mudou de verdade entre o Censo 2022 e a estimativa 2026 (ver
-- Etapa 5). Como queremos poder responder "qual era a população do estado
-- X em 2022?" DEPOIS de carregar o número novo, não dá para sobrescrever --
-- precisa de uma versão nova, preservando a antiga. Igual à Vitrine
-- reclassificando o Smartwatch Fit X (sql/04_scd_tipo2_produto.sql): UPDATE
-- fecha a versão antiga, INSERT cria a nova, tudo numa transação só.
--
-- Troque :sigla, :populacao_nova e :data_corte pelos valores de UM estado
-- que a Etapa 5 (scripts/04_carga_incremental.py) apontou como alterado,
-- repita para os demais. (Em produção isso seria um loop no Python --
-- aqui, uma vez na mão primeiro ajuda a entender o padrão.)
--
-- Rode com:
--   psql -h localhost -U postgres -d vitrine -f sql/02_scd_tipo2_populacao.sql

BEGIN;      -- abre uma transação: UPDATE e INSERT só valem juntos, de uma vez (COMMIT) ou nenhum deles (ROLLBACK)

-- fecha a versão vigente (2022): marca o fim e tira o status de "atual"
UPDATE dw_populacao.dim_estado_scd2
SET data_fim = DATE '2026-01-01', registro_atual = false
WHERE sigla = 'PE' AND ano_referencia = 2022 AND registro_atual = true;

-- abre a nova versão (2026): linha nova, com data_fim NULL (ainda vigente)
INSERT INTO dw_populacao.dim_estado_scd2 (
    id_estado, sigla, nome_estado, regiao, populacao, ano_referencia, data_inicio, data_fim, registro_atual
) VALUES (
    26, 'PE', 'Pernambuco', 'Nordeste', 9583176, 2026, DATE '2026-01-01', NULL, true
);

COMMIT;     -- confirma as 2 mudanças (UPDATE + INSERT) de uma vez só

-- confere: 2 linhas de PE (2022 fechada, 2026 vigente), ordenadas pela data de início
SELECT sk_estado, sigla, populacao, ano_referencia, data_inicio, data_fim, registro_atual
FROM dw_populacao.dim_estado_scd2
WHERE sigla = 'PE'
ORDER BY data_inicio;
