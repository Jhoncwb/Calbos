CREATE TRIGGER SPAR_REGIAO_MERCADO_PEDIDO
   ON  FAPEDIDO 
   AFTER INSERT
AS 
BEGIN
if ((select Cd_mercado from inserted) = '')
	UPDATE FAPEDIDO SET Cd_mercado = (SELECT SPAR_VEMERCAD.Cd_mercado FROM SPAR_VEMERCAD WHERE SPAR_VEMERCAD.Empresa = (SELECT Cd_cliente FROM inserted) AND SPAR_VEMERCAD.Unidade_de_negocio = (SELECT Cd_unid_de_neg FROM inserted)) WHERE Cd_pedido = (SELECT Cd_pedido FROM inserted)
END
GO

CREATE TRIGGER SPAR_REGIAO_MERCADO_NF
   ON  FANFISCA
   AFTER INSERT
AS 
BEGIN
if ((select Cd_mercado from inserted) = '')
	UPDATE FAPEDIDO SET Cd_mercado = (SELECT SPAR_VEMERCAD.Cd_mercado FROM SPAR_VEMERCAD WHERE SPAR_VEMERCAD.Empresa = (SELECT Cd_cliente FROM inserted) AND SPAR_VEMERCAD.Unidade_de_negocio = (SELECT Cd_unid_de_neg FROM inserted)) WHERE Cd_pedido = (SELECT Cd_pedido FROM inserted)
END
GO