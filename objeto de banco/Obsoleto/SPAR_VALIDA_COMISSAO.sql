alter TRIGGER [dbo].[SPAR_VALIDA_COMISSAO] ON [dbo].fapedido
AFTER UPDATE
AS


IF (select Controle from inserted) >= '30'
    
BEGIN
	
	declare @base_comissao numeric
	,@base_pedido numeric
	set @base_pedido = (select inserted.Total_faturamento from inserted) 
	set @base_comissao = (select sum(GFCPE.base_comissao) from GFCPE where GFCPE.Pedido = (select inserted.cd_pedido from inserted) and GFCPE.Representante = (select inserted.Cd_representant from inserted))

	if @base_comissao <> @base_pedido and not exists(select * from FAITEMPE where FAITEMPE.Qt_medida1 <> 0 and Cd_pedido = (select inserted.cd_pedido from inserted) )
	begin
		RAISERROR ('Existe uma divergência na comissão do pedido com o valor do pedido, por favor, revise.',18,18)
	end 

END
GO

