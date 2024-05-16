ALTER TRIGGER [dbo].[SPAR_Z_Atualiza_Bonificado] ON [dbo].[FAPEDIDO]
FOR insert,UPDATE
AS
IF TRIGGER_NESTLEVEL()>1
RETURN
Begin
	DECLARE 
	@SEQ_ITEM int
	if not exists (select * from SPARPEDDESC where pedido = (select Cd_pedido from inserted))
	begin
		insert SPARPEDDESC values ((select Cd_pedido from inserted),0,0)
	end
	
	--limpa bonific e desc fora
	DECLARE Atualiza_pedido_bonific CURSOR FOR
	select sequencia from FAITEMPE where Cd_pedido = (select cd_pedido from inserted)
	OPEN Atualiza_pedido_bonific
	FETCH Atualiza_pedido_bonific INTO @SEQ_ITEM
	WHILE(@@fetch_status = 0)
	BEGIN
		update FAITEMPE set Usritpe4 = 0,usritpe1='0', usritpe2='0' where Sequencia = @SEQ_ITEM and Cd_pedido = (select Cd_pedido from inserted) and Cd_especie  ='R';
		FETCH Atualiza_pedido_bonific INTO @SEQ_ITEM
	END
	CLOSE Atualiza_pedido_bonific
	DEALLOCATE Atualiza_pedido_bonific;
	--reprocessa bonificados
	DECLARE Atualiza_pedido_bonific CURSOR FOR
	select sequencia from FAITEMPE where Cd_pedido = (select cd_pedido from inserted)
	OPEN Atualiza_pedido_bonific
	FETCH Atualiza_pedido_bonific INTO @SEQ_ITEM
	WHILE(@@fetch_status = 0)
	BEGIN
		update FAITEMPE set Usritpe4 = Usritpe4 where Sequencia = @SEQ_ITEM and Cd_pedido = (select Cd_pedido from inserted) and Cd_especie  ='R';
		FETCH Atualiza_pedido_bonific INTO @SEQ_ITEM
	END
	CLOSE Atualiza_pedido_bonific
	DEALLOCATE Atualiza_pedido_bonific;
ENd


update CECPEDID set campo34 = isnull((select (Vl_total_descon/(SELECT SUM(FAITEMPE.Vl_total_item_l) FROM FAITEMPE  with (nolock) WHERE CD_PEDIDO=(select Cd_pedido from inserted) and Cd_especie = 'R')*100) from inserted),0) where pedido = (select Cd_pedido from inserted) and Seq_pedido = 0;