-- Teste das tabelas de anotações (executar no Supabase para verificar)
-- Teste 1: Inserir uma anotação
INSERT INTO
     anotacoes_aula (
          fk_id_agendamento_professor,
          fk_id_usuario,
          conteudo_anotacao,
          formato_conteudo,
          criado_por,
          atualizado_por
     )
VALUES
     (
          180,
          10,
          'Teste de anotação do sistema',
          'richtext',
          10,
          10
     );

-- Teste 2: Inserir um registro de áudio
INSERT INTO
     audio_aula (
          fk_id_agendamento_professor,
          fk_id_usuario,
          nome_arquivo,
          caminho_storage,
          formato_audio,
          titulo,
          status_upload,
          criado_por,
          atualizado_por
     )
VALUES
     (
          180,
          10,
          'teste-audio.webm',
          'agendamentos/180/audios/10/teste-audio.webm',
          'webm',
          'Teste de áudio',
          'pending',
          10,
          10
     );

-- Verificar se foram inseridos
SELECT
     'anotacoes' AS tipo,
     count(*) AS total
FROM
     anotacoes_aula
WHERE
     fk_id_agendamento_professor = 180
UNION
ALL
SELECT
     'audios' AS tipo,
     count(*) AS total
FROM
     audio_aula
WHERE
     fk_id_agendamento_professor = 180;