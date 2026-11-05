-- Private invoice delivery. Never expose these bytes through public file storage.
CREATE TABLE invoice_document (
    invoice_id BIGINT NOT NULL PRIMARY KEY,
    content MEDIUMBLOB NOT NULL,
    sha256 CHAR(64) NOT NULL,
    size_bytes INT NOT NULL,
    uploaded_by BIGINT NOT NULL,
    uploaded_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    received_at DATETIME NULL,
    CONSTRAINT fk_invoice_document_request FOREIGN KEY (invoice_id) REFERENCES invoice_request(id),
    CONSTRAINT ck_invoice_document_size CHECK (size_bytes BETWEEN 1 AND 5242880 AND OCTET_LENGTH(content)=size_bytes)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
