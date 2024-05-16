ALTER TRIGGER [dbo].[BONIFIC_ITENS] ON [dbo].[FAITEMPE]
FOR UPDATE
AS
IF TRIGGER_NESTLEVEL()>2
RETURN

IF UPDATE(Usritpe4) AND (SELECT QUANTIDADE FROM INSERTED)<>'0'
 AND (SELECT RTRIM(CD_PEDIDO) FROM INSERTED)!=''
 AND (SELECT CD_PEDIDO FROM inserted)!=''
 and (SELECT CD_ESPECIE FROM inserted)!='B'
 AND (SELECT CFOP FROM inserted) NOT IN ('5901','5902','5903','6901','6902','6903')
  
BEGIN

-- DECLARAÇÃO DE VARIÁVEIS
DECLARE

		 @PEDIDO VARCHAR(6)
		,@SEQ_ITEM INT
		,@ITEM_BONIF VARCHAR(20)
		,@ITEM_BONIF_STRING VARCHAR(20)
		,@ITEM_BONIF_STRING_DELETED VARCHAR(20)
		,@ITEM_BONIF_DELETED VARCHAR(20)
		,@VL_ITEM FLOAT
		,@VL_ITEM_BONIF FLOAT
		,@DESC_PEDIDO FLOAT
        ,@QTDE_BONIF FLOAT
		,@VL_Total_itens FLOAT
		,@TempValorDesconto FLOAT
		,@fatordesconto float

--DEFINE VALOR DAS PRINCIPAIS VARIÁVEIS
		
SET @PEDIDO = (SELECT CD_PEDIDO FROM INSERTED)
SET @SEQ_ITEM = (SELECT SEQUENCIA FROM INSERTED)
SET @VL_ITEM = (SELECT Vl_total_item_l FROM inserted)
SET @ITEM_BONIF_STRING = (SELECT RTRIM(CAMPO119) FROM inserted)
set @VL_Total_itens = 0

if((select Vl_total_descon from fapedido where Cd_pedido = @PEDIDO) <> 0)
begin
	update FAITEMPE set Vl_desconto = round((select (Vl_total_descon/(Total_pedido+Vl_total_descon)) from fapedido where Cd_pedido = @PEDIDO ) * Vl_total_item_l,2) where Cd_pedido = @PEDIDO and Cd_especie  ='R'
end
else
begin
	update FAITEMPE set Vl_desconto = 0 where Cd_pedido = (select Cd_pedido from inserted) and Cd_especie  ='R'
end


--//////////////////////////////////////////////////\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\--
set @VL_Total_itens = @VL_Total_itens + ISNULL((select Vl_total_item_l from inserted where campo119=@ITEM_BONIF_STRING and Cd_especie = 'R' and Sequencia = @SEQ_ITEM),0)
--set @VL_Total_itens = @VL_Total_itens + ISNULL((select FAITEMPE.Vl_total_item_l from FAITEMPE where Cd_pedido=@PEDIDO AND campo119=@ITEM_BONIF_STRING and Cd_especie = 'R' and Sequencia <> @SEQ_ITEM),0)
WHILE ((CHARINDEX(';',@ITEM_BONIF_STRING)) > 0)
	BEGIN
		/*Bonific item que gera a bonificação*/

		/*Bonific item que gera a bonificação fim*/
		SET @ITEM_BONIF = SUBSTRING(@ITEM_BONIF_STRING,1,CHARINDEX(';',@ITEM_BONIF_STRING)-1);
		SET @ITEM_BONIF_STRING = SUBSTRING(@ITEM_BONIF_STRING,CHARINDEX(';',@ITEM_BONIF_STRING)+1,50);
		--******************************************************************************************--
		set @VL_Total_itens = @VL_Total_itens + ISNULL((select FAITEMPE.Vl_total_item_l from FAITEMPE where Cd_pedido=@PEDIDO AND Sequencia=@ITEM_BONIF and Cd_especie = 'R' and Sequencia <> @SEQ_ITEM),0)
		--******************************************************************************************--
	END
			--******************************************************************************************--
set @VL_Total_itens = @VL_Total_itens + ISNULL((select FAITEMPE.Vl_total_item_l from FAITEMPE where Cd_pedido=@PEDIDO AND Sequencia=@ITEM_BONIF_STRING and Cd_especie = 'R' and Sequencia < >@SEQ_ITEM),0)

		--******************************************************************************************--
--//////////////////////////////////////////////////\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\--
SET @ITEM_BONIF_STRING = (SELECT RTRIM(CAMPO119) FROM inserted)


declare
@teste varchar(50)

--RAISERROR (@teste,16,1);
-- CONDIÇÃO PARA QUANDO O ITEM BONIFICADO FOR DIFERENTE DE '' (VAZIO)
IF RTRIM(@ITEM_BONIF_STRING) NOT IN ('','0')
BEGIN
	WHILE ((CHARINDEX(';',@ITEM_BONIF_STRING)) > 0)
	BEGIN
		SET @ITEM_BONIF = SUBSTRING(@ITEM_BONIF_STRING,1,CHARINDEX(';',@ITEM_BONIF_STRING)-1);
		SET @ITEM_BONIF_STRING = SUBSTRING(@ITEM_BONIF_STRING,CHARINDEX(';',@ITEM_BONIF_STRING)+1,50);
		--******************************************************************************************--
		SET @VL_ITEM_BONIF = (SELECT Vl_total_item_l FROM FAITEMPE with (nolock) WHERE Cd_pedido=@PEDIDO AND Sequencia=@ITEM_BONIF and Cd_especie = 'R')
		SET	@QTDE_BONIF = ISNULL((SELECT QUANTIDADE FROM FAITEMPE with (nolock) WHERE cd_pedido=@PEDIDO AND Sequencia=@ITEM_BONIF and Cd_especie = 'R'),'0')
		IF @QTDE_BONIF  <>'0'
    		BEGIN
				set @TempValorDesconto = (select (((@VL_ITEM/@QTDE_BONIF)/pr_unitario)*100)*( Vl_total_item_l/@VL_Total_itens) from faitempe WHERE Cd_pedido=@PEDIDO AND Sequencia=@ITEM_BONIF and Cd_especie = 'R')
				set @teste = cast(@TempValorDesconto as varchar(50))
				--RAISERROR (@teste,16,1);
				UPDATE FAITEMPE SET Usritpe1=Pr_unitario, Usritpe2='1'  WHERE Cd_pedido=@PEDIDO AND Sequencia=@ITEM_BONIF AND Cd_especie='R'
				set @fatordesconto = (select isnull((select isnull((select valor_Desconto_manual from SPARPEDDESC where pedido = @PEDIDO),0)/isnull((select sum(Vl_total_item_l) from faitempe where Cd_pedido = @PEDIDO and Cd_especie = 'R'),1)),0))*100
				UPDATE FAITEMPE SET Usritpe4=(isnull(@TempValorDesconto,0)+(@fatordesconto)) WHERE Cd_pedido=@PEDIDO AND Sequencia=@ITEM_BONIF AND Cd_especie='R'				
    		END
		--******************************************************************************************--
	END
	--******************************************************************************************--
	SET @VL_ITEM_BONIF = (SELECT Vl_total_item_l FROM FAITEMPE with (nolock) WHERE Cd_pedido=@PEDIDO AND Sequencia=@ITEM_BONIF_STRING and Cd_especie = 'R')
	SET	@QTDE_BONIF = ISNULL((SELECT QUANTIDADE FROM FAITEMPE with (nolock) WHERE cd_pedido=@PEDIDO AND Sequencia=@ITEM_BONIF_STRING and Cd_especie = 'R'),'0')
	IF @QTDE_BONIF  <>'0'
    	BEGIN
			if(@SEQ_ITEM <> @ITEM_BONIF_STRING)
				set @TempValorDesconto = (select (((@VL_ITEM/@QTDE_BONIF)/pr_unitario)*100)*(Vl_total_item_l/@VL_Total_itens) from faitempe WHERE Cd_pedido=@PEDIDO AND Sequencia=@ITEM_BONIF_STRING and Cd_especie = 'R')
			else
				set @TempValorDesconto = 100;
			set @teste = cast(@TempValorDesconto as varchar(50))
			--RAISERROR (@ITEM_BONIF_STRING,16,1);
			UPDATE FAITEMPE SET Usritpe1=Pr_unitario, Usritpe2='1'  WHERE Cd_pedido=@PEDIDO AND Sequencia=@ITEM_BONIF_STRING AND Cd_especie='R'
			set @fatordesconto = (select isnull((select isnull((select valor_Desconto_manual from SPARPEDDESC where pedido = @PEDIDO),0)/isnull((select sum(Vl_total_item_l) from faitempe where Cd_pedido = @PEDIDO and Cd_especie = 'R'),1)),0))*100
			UPDATE FAITEMPE SET Usritpe4=(isnull(@TempValorDesconto,0)+(@fatordesconto)) WHERE Cd_pedido=@PEDIDO AND Sequencia=@ITEM_BONIF_STRING AND Cd_especie='R'
    	END
	--******************************************************************************************--
END



-- CONDIÇÃO PARA QUANDO O ITEM BONIFICADO FOR IGUAL DE '' (VAZIO)

IF UPDATE(Usritpe4) and RTRIM(@ITEM_BONIF_STRING) IN ('','0') and ((select Usritpe4 from inserted)=0)
	BEGIN
		set @fatordesconto = (select isnull((select isnull((select valor_Desconto_manual from SPARPEDDESC where pedido = @PEDIDO),0)/isnull((select sum(Vl_total_item_l) from faitempe where Cd_pedido = @PEDIDO and Cd_especie = 'R'),1)),0))*100
		UPDATE FAITEMPE SET Usritpe4=(@fatordesconto), usritpe1='0', usritpe2='0' WHERE Cd_pedido=@PEDIDO AND Sequencia=@SEQ_ITEM AND Cd_especie='R'
		
    END



SET @DESC_PEDIDO = (SELECT SUM(FAITEMPE.Vl_total_item_l) FROM FAITEMPE with (nolock) WHERE CD_PEDIDO=@PEDIDO AND RTRIM(CAMPO119)NOT IN ('','0') and Cd_especie = 'R') 
--PRINT @DESC_PEDIDO
--ATUALIZANDO DESCONTO DO PEDIDO
update SPARPEDDESC set valor_desconto_bonificado = isnull(@DESC_PEDIDO,0) where pedido = @PEDIDO;

SET @DESC_PEDIDO = (select valor_desconto_bonificado + valor_desconto_manual from SPARPEDDESC where pedido = @PEDIDO)

UPDATE FAPEDIDO 
	SET FAPEDIDO.Vl_total_descon = @DESC_PEDIDO, 
        FAPEDIDO.Campo115=@DESC_PEDIDO,
		FAPEDIDO.Total_de_mercad=(SELECT SUM(FAITEMPE.Vl_total_item_l) FROM FAITEMPE  with (nolock) WHERE CD_PEDIDO=@PEDIDO and Cd_especie = 'R')-@DESC_PEDIDO, 
        FAPEDIDO.Total_faturamento=Vl_frete+(SELECT SUM(FAITEMPE.Vl_total_item_l) FROM FAITEMPE  with (nolock) WHERE CD_PEDIDO=@PEDIDO and Cd_especie = 'R')-@DESC_PEDIDO, 
        FAPEDIDO.Total_pedido=Vl_frete+(SELECT SUM(FAITEMPE.Vl_total_item_l) FROM FAITEMPE  with (nolock) WHERE CD_PEDIDO=@PEDIDO and Cd_especie = 'R')-@DESC_PEDIDO,
        FAPEDIDO.usrpedi3='1'
WHERE CD_PEDIDO=@PEDIDO

END
