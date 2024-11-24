use meubanco;

CREATE TABLE mensagens (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(100),
    email VARCHAR(100),
    comentario VARCHAR(500)
);

INSERT INTO mensagens (id, nome, email, comentario) VALUES (1, 'Wilian Andrade', 'williandrade@gmail.com', 'Primeiro comentário no banco de dados.');
