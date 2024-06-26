USE [CIGAM]
GO

/****** Object:  Trigger [dbo].[BONIFIC_ITENS]    Script Date: 14/08/2016 17:56:43 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE TRIGGER [dbo].[BONIFIC_ITENS] ON [dbo].[FAITEMPE]
WITH EXECUTE AS CALLER
FOR UPDATE
AS
IF TRIGGER_NESTLEVEL()>1
RETURN

IF UPDATE(CAMPO119) and (SELECT QUANTIDADE FROM INSERTED)<>'0'
 AND (SELECT RTRIM(CD_PEDIDO) FROM INSERTED)!='' --OR UPDATE(Controle)
 AND (SELECT CD_PEDIDO FROM inserted)!=''
 and (SELECT CD_ESPECIE FROM inserted)!='B'
 
BEGIN

-- DECLARA��O DE VARI�VEIS
DECLARE

		 @PEDIDO VARCHAR(6)
		,@ITEM VARCHAR(7)
		,@SEQ_ITEM INT
		,@ITEM_BONIF VARCHAR(20)
		,@ITEM_BONIF_STRING VARCHAR(20)
		,@ITEM_BONIF_STRING_DELETED VARCHAR(20)
		,@ITEM_BONIF_DELETED VARCHAR(20)
		,@VL_ITEM FLOAT
		,@VL_ITEM_BONIF FLOAT
		,@DESC_PEDIDO FLOAT
		,@PE_DESC FLOAT
		,@PR_UNIT FLOAT
		,@MSG VARCHAR(100)
        ,@QTDE_BONIF FLOAT
		,@VL_Total_itens FLOAT
		,@TempValorDesconto FLOAT

--DEFINE VALOR DAS PRINCIPAIS VARI�VEIS
		
SET @PEDIDO = (SELECT CD_PEDIDO FROM INSERTED)
SET @ITEM = (SELECT CD_MATERIAL FROM INSERTED)
SET @SEQ_ITEM = (SELECT SEQUENCIA FROM INSERTED)
SET @VL_ITEM = (SELECT Vl_total_item_l FROM inserted)
SET @PR_UNIT = (SELECT Pr_unitario FROM inserted)
SET @ITEM_BONIF_STRING = (SELECT RTRIM(CAMPO119) FROM inserted)
set @VL_Total_itens = 0

--//////////////////////////////////////////////////\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\--
set @VL_Total_itens = @VL_Total_itens + (select FAITEMPE.Vl_total_item_l from FAITEMPE where Cd_pedido=@PEDIDO AND campo119=@ITEM_BONIF_STRING and Cd_especie = 'R')
WHILE ((CHARINDEX(';',@ITEM_BONIF_STRING)) > 0)
	BEGIN
		/*Bonific item que gera a bonifica��o*/

		/*Bonific item que gera a bonifica��o fim*/
		SET @ITEM_BONIF = SUBSTRING(@ITEM_BONIF_STRING,1,CHARINDEX(';',@ITEM_BONIF_STRING)-1);
		SET @ITEM_BONIF_STRING = SUBSTRING(@ITEM_BONIF_STRING,CHARINDEX(';',@ITEM_BONIF_STRING)+1,50);
		--******************************************************************************************--
		set @VL_Total_itens = @VL_Total_itens + (select FAITEMPE.Vl_total_item_l from FAITEMPE where Cd_pedido=@PEDIDO AND Sequencia=@ITEM_BONIF and Cd_especie = 'R')
		--******************************************************************************************--
	END
			--******************************************************************************************--
set @VL_Total_itens = @VL_Total_itens + (select FAITEMPE.Vl_total_item_l from FAITEMPE where Cd_pedido=@PEDIDO AND Sequencia=@ITEM_BONIF_STRING and Cd_especie = 'R')

		--******************************************************************************************--
--//////////////////////////////////////////////////\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\--
SET @ITEM_BONIF_STRING = (SELECT RTRIM(CAMPO119) FROM inserted)


declare
@teste varchar(50)

--RAISERROR (@teste,16,1);
-- CONDI��O PARA QUANDO O ITEM BONIFICADO FOR DIFERENTE DE '' (VAZIO)
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
				UPDATE FAITEMPE SET Usritpe1=Pr_unitario,Usritpe2='1'  WHERE Cd_pedido=@PEDIDO AND Sequencia=@ITEM_BONIF AND Cd_especie='R'
				UPDATE FAITEMPE SET Usritpe4=@TempValorDesconto WHERE Cd_pedido=@PEDIDO AND Sequencia=@ITEM_BONIF AND Cd_especie='R'

    		END
		--******************************************************************************************--
	END
	--******************************************************************************************--
	SET @VL_ITEM_BONIF = (SELECT Vl_total_item_l FROM FAITEMPE with (nolock) WHERE Cd_pedido=@PEDIDO AND Sequencia=@ITEM_BONIF_STRING and Cd_especie = 'R')
	SET	@QTDE_BONIF = ISNULL((SELECT QUANTIDADE FROM FAITEMPE with (nolock) WHERE cd_pedido=@PEDIDO AND Sequencia=@ITEM_BONIF_STRING and Cd_especie = 'R'),'0')
	IF @QTDE_BONIF  <>'0'
    	BEGIN
			set @TempValorDesconto = (select (((@VL_ITEM/@QTDE_BONIF)/pr_unitario)*100)*( Vl_total_item_l/@VL_Total_itens)  from faitempe WHERE Cd_pedido=@PEDIDO AND Sequencia=@ITEM_BONIF_STRING and Cd_especie = 'R')
			set @teste = cast(@TempValorDesconto as varchar(50))
			--RAISERROR (@ITEM_BONIF_STRING,16,1);
			UPDATE FAITEMPE SET Usritpe1=Pr_unitario,Usritpe2='1'  WHERE Cd_pedido=@PEDIDO AND Sequencia=@ITEM_BONIF_STRING AND Cd_especie='R'
			UPDATE FAITEMPE SET Usritpe4=@TempValorDesconto WHERE Cd_pedido=@PEDIDO AND Sequencia=@ITEM_BONIF_STRING AND Cd_especie='R'
    	END
	--******************************************************************************************--
END



-- CONDI��O PARA QUANDO O ITEM BONIFICADO FOR IGUAL DE '' (VAZIO)

IF UPDATE(CAMPO119) and RTRIM(@ITEM_BONIF_STRING) IN ('','0')
	BEGIN
		set @ITEM_BONIF_STRING_DELETED = (SELECT RTRIM(CAMPO119) FROM deleted);
		WHILE ((SELECT CHARINDEX(';',@ITEM_BONIF_STRING_DELETED)) > 0)
		BEGIN
			SET @ITEM_BONIF_DELETED = SUBSTRING(@ITEM_BONIF_STRING_DELETED,1,CHARINDEX(';',@ITEM_BONIF_STRING_DELETED)-1);
			SET @ITEM_BONIF_STRING_DELETED = SUBSTRING(@ITEM_BONIF_STRING_DELETED,CHARINDEX(';',@ITEM_BONIF_STRING_DELETED)+1,50);
			--******************************************************************************************--
			UPDATE FAITEMPE SET Usritpe4='0', usritpe1='0', usritpe2='0' WHERE Cd_pedido=@PEDIDO AND Sequencia=@ITEM_BONIF_DELETED AND Cd_especie='R'
			--******************************************************************************************--
		end
			--******************************************************************************************--
			UPDATE FAITEMPE SET Usritpe4='0', usritpe1='0', usritpe2='0' WHERE Cd_pedido=@PEDIDO AND Sequencia=@ITEM_BONIF_STRING_DELETED AND Cd_especie='R'
			--******************************************************************************************--
    END



SET @DESC_PEDIDO = (SELECT SUM(FAITEMPE.Vl_total_item_l) FROM FAITEMPE with (nolock) WHERE CD_PEDIDO=@PEDIDO AND RTRIM(CAMPO119)NOT IN ('','0')) 
--PRINT @DESC_PEDIDO
--ATUALIZANDO DESCONTO DO PEDIDO
IF @DESC_PEDIDO <>'0'
BEGIN
	UPDATE FAPEDIDO 
		SET FAPEDIDO.Vl_total_descon = @DESC_PEDIDO, 
        	FAPEDIDO.Campo115=@DESC_PEDIDO,
			FAPEDIDO.Total_de_mercad=FAPEDIDO.Total_de_mercad-@DESC_PEDIDO, 
            FAPEDIDO.Total_faturamento=FAPEDIDO.Total_faturamento-@DESC_PEDIDO, 
            FAPEDIDO.Total_pedido=FAPEDIDO.Total_pedido-@DESC_PEDIDO,
            FAPEDIDO.usrpedi3='1'
	WHERE CD_PEDIDO=@PEDIDO -- AND FAPEDIDO.usrpedi3='0'
END
ELSE
BEGIN
	UPDATE FAPEDIDO 
		SET FAPEDIDO.Vl_total_descon = '0', 
        	FAPEDIDO.Campo115='0',
			FAPEDIDO.Total_de_mercad=(SELECT SUM(FAITEMPE.Vl_total_item_l) FROM FAITEMPE  with (nolock) WHERE CD_PEDIDO=@PEDIDO and Cd_especie = 'R'), 
            FAPEDIDO.Total_faturamento=(SELECT SUM(FAITEMPE.Vl_total_item_l) FROM FAITEMPE  with (nolock)WHERE CD_PEDIDO=@PEDIDO and Cd_especie = 'R'), 
            FAPEDIDO.Total_pedido=(SELECT SUM(FAITEMPE.Vl_total_item_l) FROM FAITEMPE with (nolock) WHERE CD_PEDIDO=@PEDIDO and Cd_especie = 'R'),
            FAPEDIDO.usrpedi3='0'
	WHERE CD_PEDIDO=@PEDIDO
END
END




GO

