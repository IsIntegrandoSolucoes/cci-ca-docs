-- Migration: Criar tabelas para sistema de anotações de aula
-- Data: 2025-09-23
-- Descrição: Tabelas para armazenar anotações RichText e metadados de áudios gravados pelos alunos
-- Tabela para anotações de texto dos alunos por agendamento
CREATE TABLE anotacoes_aula (
     id BIGSERIAL PRIMARY KEY,
     fk_id_agendamento_professor BIGINT NOT NULL REFERENCES agendamentos_professores(id) ON DELETE CASCADE,
     fk_id_usuario BIGINT NOT NULL REFERENCES pessoas(id) ON DELETE CASCADE,
     conteudo_anotacao TEXT DEFAULT '',
     formato_conteudo VARCHAR(20) DEFAULT 'richtext' CHECK (
          formato_conteudo IN ('richtext', 'markdown', 'plain')
     ),
     versao_editor VARCHAR(50) DEFAULT '1.0',
     -- Metadados de sincronização
     ultima_edicao TIMESTAMPTZ DEFAULT NOW(),
     sincronizado BOOLEAN DEFAULT TRUE,
     backup_local TEXT,
     -- Para armazenar backup quando offline
     -- Controle de auditoria
     data_criacao TIMESTAMPTZ DEFAULT NOW(),
     data_atualizacao TIMESTAMPTZ DEFAULT NOW(),
     criado_por BIGINT REFERENCES pessoas(id),
     atualizado_por BIGINT REFERENCES pessoas(id),
     -- Índices únicos
     UNIQUE(fk_id_agendamento_professor, fk_id_usuario)
);

-- Tabela para metadados de áudios gravados pelos alunos
CREATE TABLE audio_aula (
     id BIGSERIAL PRIMARY KEY,
     fk_id_agendamento_professor BIGINT NOT NULL REFERENCES agendamentos_professores(id) ON DELETE CASCADE,
     fk_id_usuario BIGINT NOT NULL REFERENCES pessoas(id) ON DELETE CASCADE,
     -- Informações do arquivo
     nome_arquivo VARCHAR(255) NOT NULL,
     caminho_storage TEXT NOT NULL,
     -- Caminho no Supabase Storage
     bucket_name VARCHAR(100) DEFAULT 'audio-anotacoes' NOT NULL,
     tamanho_bytes BIGINT,
     formato_audio VARCHAR(20) DEFAULT 'webm' CHECK (formato_audio IN ('webm', 'mp3', 'wav', 'ogg')),
     -- Metadados de áudio
     duracao_segundos DECIMAL(10, 2),
     qualidade_audio VARCHAR(20) DEFAULT 'medium' CHECK (qualidade_audio IN ('low', 'medium', 'high')),
     taxa_amostragem INTEGER DEFAULT 44100,
     -- Informações adicionais
     titulo VARCHAR(255),
     descricao TEXT,
     transcricao TEXT,
     -- Para futuras implementações de transcrição automática
     -- Status do upload
     status_upload VARCHAR(20) DEFAULT 'pending' CHECK (
          status_upload IN ('pending', 'uploading', 'completed', 'failed')
     ),
     erro_upload TEXT,
     progresso_upload INTEGER DEFAULT 0 CHECK (
          progresso_upload >= 0
          AND progresso_upload <= 100
     ),
     -- Controle de auditoria
     data_criacao TIMESTAMPTZ DEFAULT NOW(),
     data_atualizacao TIMESTAMPTZ DEFAULT NOW(),
     criado_por BIGINT REFERENCES pessoas(id),
     atualizado_por BIGINT REFERENCES pessoas(id)
);

-- Índices para performance
CREATE INDEX idx_anotacoes_aula_agendamento_usuario ON anotacoes_aula(fk_id_agendamento_professor, fk_id_usuario);

CREATE INDEX idx_anotacoes_aula_usuario ON anotacoes_aula(fk_id_usuario);

CREATE INDEX idx_anotacoes_aula_ultima_edicao ON anotacoes_aula(ultima_edicao);

CREATE INDEX idx_audio_aula_agendamento_usuario ON audio_aula(fk_id_agendamento_professor, fk_id_usuario);

CREATE INDEX idx_audio_aula_usuario ON audio_aula(fk_id_usuario);

CREATE INDEX idx_audio_aula_status ON audio_aula(status_upload);

CREATE INDEX idx_audio_aula_data_criacao ON audio_aula(data_criacao);

-- Triggers para atualização automática de data_atualizacao
CREATE
OR REPLACE FUNCTION update_data_atualizacao() RETURNS TRIGGER AS $ $ BEGIN NEW.data_atualizacao = NOW();

RETURN NEW;

END;

$ $ LANGUAGE plpgsql;

CREATE TRIGGER trigger_anotacoes_aula_updated_at BEFORE
UPDATE
     ON anotacoes_aula FOR EACH ROW EXECUTE FUNCTION update_data_atualizacao();

CREATE TRIGGER trigger_audio_aula_updated_at BEFORE
UPDATE
     ON audio_aula FOR EACH ROW EXECUTE FUNCTION update_data_atualizacao();

-- Políticas RLS (Row Level Security)
ALTER TABLE
     anotacoes_aula ENABLE ROW LEVEL SECURITY;

ALTER TABLE
     audio_aula ENABLE ROW LEVEL SECURITY;

-- Política para anotações: usuários só podem ver/editar suas próprias anotações
CREATE POLICY "usuarios_acessam_proprias_anotacoes" ON anotacoes_aula FOR ALL USING (
     fk_id_usuario = (
          SELECT
               id
          FROM
               pessoas
          WHERE
               email = auth.jwt() ->> 'email'
     )
);

-- Política para áudios: usuários só podem ver/editar seus próprios áudios
CREATE POLICY "usuarios_acessam_proprios_audios" ON audio_aula FOR ALL USING (
     fk_id_usuario = (
          SELECT
               id
          FROM
               pessoas
          WHERE
               email = auth.jwt() ->> 'email'
     )
);

-- Política para admins visualizarem anotações (apenas SELECT)
CREATE POLICY "admins_visualizam_anotacoes" ON anotacoes_aula FOR
SELECT
     USING (
          EXISTS (
               SELECT
                    1
               FROM
                    pessoas u
               WHERE
                    u.email = auth.jwt() ->> 'email'
                    AND u.fk_id_tipo_pessoa = 3 -- Admin type
          )
     );

-- Política para admins visualizarem áudios (apenas SELECT)
CREATE POLICY "admins_visualizam_audios" ON audio_aula FOR
SELECT
     USING (
          EXISTS (
               SELECT
                    1
               FROM
                    pessoas u
               WHERE
                    u.email = auth.jwt() ->> 'email'
                    AND u.fk_id_tipo_pessoa = 3 -- Admin type
          )
     );

-- Comentários nas tabelas
COMMENT ON TABLE anotacoes_aula IS 'Armazena anotações em formato RichText dos alunos para cada agendamento de aula';

COMMENT ON TABLE audio_aula IS 'Armazena metadados dos áudios gravados pelos alunos durante as aulas';

COMMENT ON COLUMN anotacoes_aula.conteudo_anotacao IS 'Conteúdo da anotação em formato RichText (JSON ou HTML)';

COMMENT ON COLUMN anotacoes_aula.formato_conteudo IS 'Tipo de formato do conteúdo (richtext, markdown, plain)';

COMMENT ON COLUMN anotacoes_aula.versao_editor IS 'Versão do editor usado para criação/edição';

COMMENT ON COLUMN anotacoes_aula.sincronizado IS 'Indica se a anotação está sincronizada com o servidor';

COMMENT ON COLUMN anotacoes_aula.backup_local IS 'Backup do conteúdo para recuperação offline';

COMMENT ON COLUMN audio_aula.caminho_storage IS 'Caminho completo do arquivo no Supabase Storage';

COMMENT ON COLUMN audio_aula.bucket_name IS 'Nome do bucket onde o arquivo está armazenado';

COMMENT ON COLUMN audio_aula.duracao_segundos IS 'Duração do áudio em segundos';

COMMENT ON COLUMN audio_aula.transcricao IS 'Transcrição automática do áudio (futuro)';

COMMENT ON COLUMN audio_aula.status_upload IS 'Status atual do upload do arquivo';