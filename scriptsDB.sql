CREATE TABLE cadastro (
    id SERIAL PRIMARY KEY,

    ra VARCHAR(8) UNIQUE,

    nome VARCHAR(150) NOT NULL,
    cpf VARCHAR(11) UNIQUE NOT NULL,
    endereco VARCHAR(200),
    telefone VARCHAR(20),
    email VARCHAR(150) UNIQUE NOT NULL,

    tipo_usuario VARCHAR(20) NOT NULL
        CHECK (tipo_usuario IN (
            'Aluno',
            'Professor',
            'Administrador'
        )),

    -- RA obrigatório somente para alunos
    CONSTRAINT chk_ra_aluno CHECK (
        tipo_usuario <> 'Aluno'
        OR ra IS NOT NULL
    )
);



CREATE TABLE login (
    id SERIAL PRIMARY KEY,

    cadastro_id INT UNIQUE NOT NULL,

    -- Armazena o hash BCrypt da senha
    senha VARCHAR(255) NOT NULL,

    data_alteracao TIMESTAMP
        DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_login_cadastro
        FOREIGN KEY (cadastro_id)
        REFERENCES cadastro(id)
        ON DELETE CASCADE
);



SELECT
    l.id AS login_id,
    c.id AS cadastro_id,
    c.nome,
    c.email,
    c.tipo_usuario,
    l.senha
FROM login l
INNER JOIN cadastro c
    ON l.cadastro_id = c.id
WHERE c.email = 'aluno@cosmoshub.com';


CREATE TABLE publicacoes (
    id SERIAL PRIMARY KEY,

    cadastro_id INT NOT NULL,

    titulo VARCHAR(150) NOT NULL,
    conteudo TEXT NOT NULL,

    status VARCHAR(20) NOT NULL
        DEFAULT 'Pendente'
        CHECK (status IN (
            'Pendente',
            'Aprovado',
            'Rejeitado'
        )),

    excluido BOOLEAN NOT NULL DEFAULT FALSE,

    data_criacao TIMESTAMP
        DEFAULT CURRENT_TIMESTAMP,

    data_edicao TIMESTAMP,

    data_aprovacao TIMESTAMP,

    aprovado_por INT,

    CONSTRAINT fk_publicacao_usuario
        FOREIGN KEY (cadastro_id)
        REFERENCES cadastro(id),

    CONSTRAINT fk_publicacao_admin
        FOREIGN KEY (aprovado_por)
        REFERENCES cadastro(id)
);



CREATE TABLE curtidas (
    id SERIAL PRIMARY KEY,

    publicacao_id INT NOT NULL,
    cadastro_id INT NOT NULL,

    curtida_ativa BOOLEAN NOT NULL DEFAULT TRUE,

    data_primeira_curtida TIMESTAMP
        DEFAULT CURRENT_TIMESTAMP,

    data_ultima_interacao TIMESTAMP
        DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_curtida_publicacao
        FOREIGN KEY (publicacao_id)
        REFERENCES publicacoes(id),

    CONSTRAINT fk_curtida_usuario
        FOREIGN KEY (cadastro_id)
        REFERENCES cadastro(id),

    CONSTRAINT uq_curtida_usuario_publicacao
        UNIQUE (publicacao_id, cadastro_id)
);



CREATE TABLE historico_xp (
    id SERIAL PRIMARY KEY,

    cadastro_id INT NOT NULL,
    publicacao_id INT NOT NULL,

    origem_usuario_id INT,

    tipo_acao VARCHAR(20) NOT NULL
        CHECK (tipo_acao IN (
            'Publicacao',
            'Curtida'
        )),

    pontos INT NOT NULL
        CHECK (pontos > 0),

    data_concessao TIMESTAMP
        DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_xp_usuario
        FOREIGN KEY (cadastro_id)
        REFERENCES cadastro(id),

    CONSTRAINT fk_xp_publicacao
        FOREIGN KEY (publicacao_id)
        REFERENCES publicacoes(id),

    CONSTRAINT fk_xp_origem
        FOREIGN KEY (origem_usuario_id)
        REFERENCES cadastro(id),

    CONSTRAINT chk_xp_valor CHECK (
        (
            tipo_acao = 'Publicacao'
            AND pontos = 20
            AND origem_usuario_id IS NULL
        )
        OR
        (
            tipo_acao = 'Curtida'
            AND pontos = 2
            AND origem_usuario_id IS NOT NULL
        )
    )
);



CREATE UNIQUE INDEX uq_xp_publicacao
ON historico_xp (publicacao_id)
WHERE tipo_acao = 'Publicacao';



CREATE UNIQUE INDEX uq_xp_curtida
ON historico_xp (publicacao_id, origem_usuario_id)
WHERE tipo_acao = 'Curtida';



SELECT
    ROW_NUMBER() OVER (
        ORDER BY
            COALESCE(SUM(h.pontos), 0) DESC,
            c.nome ASC,
            c.id ASC
    ) AS posicao,

    c.id,
    c.ra,
    c.nome,

    COALESCE(SUM(h.pontos), 0) AS xp_total

FROM cadastro c

LEFT JOIN historico_xp h
    ON h.cadastro_id = c.id

WHERE c.tipo_usuario = 'Aluno'

GROUP BY
    c.id,
    c.ra,
    c.nome

ORDER BY
    xp_total DESC,
    c.nome ASC,
    c.id ASC;
