
ALTER TRIGGER [dbo].[SPAR_DESCONTO_FORA] ON FAPEDIDO
WITH EXECUTE AS CALLER
FOR UPDATE
AS
IF TRIGGER_NESTLEVEL()>1
RETURN

IF UPDATE(Vl_total_descon)
 
BEGIN

DECLARE

		@PEDIDO VARCHAR(6)
		,@DESC_PEDIDO FLOAT
		
		set @DESC_PEDIDO = (select Vl_total_descon/(Vl_total_descon+Total_pedido) from inserted)*100;
		set @PEDIDO = (select cd_pedido from inserted);
		update faitempe set Usritpe4 = @DESC_PEDIDO where Cd_pedido = @PEDIDO;

END

GO

