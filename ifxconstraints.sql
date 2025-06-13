ALTER TABLE zona ADD CONSTRAINT FOREIGN KEY (zoncidcodigo) REFERENCES cidade(cidcodigo);
ALTER TABLE bairro ADD CONSTRAINT FOREIGN KEY (baizoncodigo) REFERENCES zona(zoncodigo);
ALTER TABLE cliente ADD CONSTRAINT FOREIGN KEY (clibaicodigo) REFERENCES bairro(baicodigo);
ALTER TABLE cliente ADD CONSTRAINT FOREIGN KEY (cliestcodigo) REFERENCES estadocivil(estcodigo);
ALTER TABLE funcionario ADD CONSTRAINT FOREIGN KEY (funbaicodigo) REFERENCES bairro(baicodigo);
ALTER TABLE funcionario ADD CONSTRAINT FOREIGN KEY (funcodgerente) REFERENCES funcionario(funcodigo);
ALTER TABLE funcionario ADD CONSTRAINT FOREIGN KEY (funestcodigo) REFERENCES estadocivil(estcodigo);
ALTER TABLE filial ADD CONSTRAINT FOREIGN KEY (filbaicodigo) REFERENCES bairro(baicodigo);
ALTER TABLE filial ADD CONSTRAINT FOREIGN KEY (filcodgerente) REFERENCES funcionario(funcodigo);
ALTER TABLE fornecedor ADD CONSTRAINT FOREIGN KEY (forcidcodigo) REFERENCES cidade(cidcodigo);
ALTER TABLE fornecedorfone ADD CONSTRAINT FOREIGN KEY (ffforcnpj) REFERENCES fornecedor(forcnpj);
ALTER TABLE produto ADD CONSTRAINT FOREIGN KEY (progrpcodigo) REFERENCES grupoproduto(grpcodigo);
ALTER TABLE produto ADD CONSTRAINT FOREIGN KEY (proforcnpj) REFERENCES fornecedor(forcnpj);
ALTER TABLE venda ADD CONSTRAINT FOREIGN KEY (venfilcodigo) REFERENCES filial(filcodigo);
ALTER TABLE venda ADD CONSTRAINT FOREIGN KEY (venclicodigo) REFERENCES cliente(clicodigo);
ALTER TABLE venda ADD CONSTRAINT FOREIGN KEY (venfuncodigo) REFERENCES vendedor(vefuncodigo);
ALTER TABLE venda ADD CONSTRAINT FOREIGN KEY (venfpcodigo) REFERENCES formapagamento(fpcodigo);
ALTER TABLE itemvenda ADD CONSTRAINT FOREIGN KEY (itvvencodigo) REFERENCES venda(vencodigo);
ALTER TABLE itemvenda ADD CONSTRAINT FOREIGN KEY (itvprocodigo) REFERENCES produto(procodigo);

-- Criação de índices que existiam no dump original (geralmente chaves estrangeiras)
CREATE INDEX ix_zona_cid ON zona(zoncidcodigo);
CREATE INDEX ix_bairro_zona ON bairro(baizoncodigo);
CREATE INDEX ix_cliente_bairro ON cliente(clibaicodigo);
CREATE INDEX ix_cliente_estcivil ON cliente(cliestcodigo);