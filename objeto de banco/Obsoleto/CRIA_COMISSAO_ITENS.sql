ALTER TRIGGER [dbo].[CRIA_COMISSAO_ITENS] ON [dbo].[FAITEMPE]
AFTER UPDATE
AS
IF TRIGGER_NESTLEVEL()>3
RETURN

IF (SELECT QUANTIDADE FROM INSERTED)>'0' 
	AND (SELECT RTRIM(CD_PEDIDO) FROM INSERTED)!=''
    AND (select pr_unitario from inserted)>'0'
    AND (SELECT situacao from inserted) IN ('A','L')
    AND (SELECT GETOPERA.Faturado FROM GETOPERA with(nolock) WHERE GETOPERA.Cd_tipo_operaca=(SELECT Cd_tipo_operaca FROM INSERTED))!='N'
    AND UPDATE(controle)
    AND (SELECT LEN(CD_CLIENTE) FROM FAPEDIDO with(nolock) WHERE Cd_pedido=(SELECT Cd_pedido FROM inserted))='6'
    and (SELECT CD_ESPECIE FROM inserted)!='B'
    
BEGIN

DELETE FROM GFCPE WHERE PEDIDO=(select cd_pedido from inserted) AND Sequencia_Pedido=(select sequencia from inserted)


DECLARE

		 @PEDIDO VARCHAR(6)
		,@ITEM VARCHAR(7)
		,@SEQ_ITEM INT
		,@TABELA_PRECO VARCHAR(6)
		,@VL_PEDIDO FLOAT
		,@VL_ITEM FLOAT
		,@DESC_PEDIDO FLOAT
		,@DESC_RATEIO FLOAT
		,@PE_DESC REAL
   		,@PE_DESC2 FLOAT
   		,@CLIENTE VARCHAR(6)
		,@BASE_COMIS FLOAT
		,@REPR_EXT VARCHAR(6)
		,@REPR_SUP VARCHAR(6)
		,@FAIXA_REP_EXT VARCHAR(6)
		,@PE_REP_EXT FLOAT
		,@PE_REP_SUP FLOAT
		,@MSG VARCHAR(100)
		,@TIPO_COMISSAO VARCHAR(1) -- T - TABELA / I - TG ITEM / - E - TG EMPRESA / C - CONFIGURAÇÃO
		,@PR_UNITARIO FLOAT
		,@TABELA VARCHAR
		,@PR_TABELA FLOAT
		,@VL_DESC FLOAT
   		,@OBS VARCHAR
  

-- FIM DE DECLARAÇÃO DE VARIÁVEIS		
        
-- DEFINIÇÃO DE VALORES DE PRINCIPAIS VARIÁVEIS



SET @PEDIDO = (SELECT CD_PEDIDO FROM INSERTED)
SET @ITEM = (SELECT CD_MATERIAL FROM INSERTED)
SET @SEQ_ITEM = (SELECT SEQUENCIA FROM INSERTED)
/*se bonificado, não mexe na base, senao mexe */
if (select Usritpe2 from inserted)= 1
begin
	SET @BASE_COMIS = ISNULL((SELECT VL_TOTAL_ITEM_L FROM INSERTED),'0')
end
else
begin 
	if (select sum(VL_TOTAL_ITEM_L) from FAITEMPE where Cd_pedido = @PEDIDO and campo119 NOT IN ('','0')) = (select Vl_total_descon from FAPEDIDO where Cd_pedido = @PEDIDO)
	begin
		SET @BASE_COMIS = ISNULL((SELECT VL_TOTAL_ITEM_L FROM INSERTED),'0')
	end
	else
	begin
		SET @BASE_COMIS = ISNULL((SELECT VL_TOTAL_ITEM_L FROM INSERTED),'0') - (ISNULL((SELECT VL_TOTAL_ITEM_L FROM INSERTED),'0')*isnull((select (Vl_total_descon-isnull((select Vl_total_item_l from faitempe where cd_pedido = @PEDIDO and ( case when (isnumeric(campo119)=1) then campo119 else 0 end) = sequencia),0))/((Vl_total_descon-isnull((select Vl_total_item_l from faitempe where cd_pedido = @PEDIDO and ( case when (isnumeric(campo119)=1) then campo119 else 0 end) = sequencia),0))+Total_pedido) from fapedido where cd_pedido = @PEDIDO),0))
	end
end


SET @DESC_PEDIDO = (SELECT VL_TOTAL_DESCON FROM FAPEDIDO  with (nolock) WHERE Cd_pedido=@PEDIDO)
SET @VL_PEDIDO = ISNULL((SELECT SUM(VL_TOTAL_ITEM_L) FROM FAITEMPE with (nolock) WHERE CD_PEDIDO=@PEDIDO),'1')
SET @TABELA_PRECO = ISNULL((SELECT PR_TABELA FROM inserted),'')
SET @REPR_EXT = ISNULL((SELECT CD_REPRESENTANT FROM FAPEDIDO  with (nolock) WHERE CD_PEDIDO=@PEDIDO),'')
SET @REPR_SUP = ISNULL((SELECT CD_RESPONSAVEL FROM GEEMPRES  with (nolock) WHERE CD_EMPRESA=@REPR_EXT),'')
SET @PE_REP_SUP = ISNULL((SELECT GEEMPRES.Pe_comis_baixa FROM GEEMPRES with (nolock) WHERE CD_EMPRESA=@REPR_SUP),'')
SET @PR_UNITARIO = (SELECT PR_UNITARIO FROM INSERTED)
SET @PR_TABELA  = ISNULL((SELECT MAX(PR_UNITARIO)FROM GEPRECTA  with (nolock)WHERE	TB_PRECO=@TABELA_PRECO AND ELEMENTO=@ITEM),(SELECT PR_UNITARIO FROM INSERTED))
SET @VL_DESC = @PR_TABELA - @PR_UNITARIO
SET @PE_DESC = (SELECT Usritpe4 FROM inserted)
SET @PE_DESC2 = (SELECT Pe_desconto FROM inserted)
SET @PE_DESC2 = @PE_DESC + @PE_DESC2
SET @PE_REP_EXT = '0'
SET @CLIENTE = (SELECT FAPEDIDO.Cd_cliente FROM FAPEDIDO with(nolock) WHERE Cd_pedido=@PEDIDO)

IF (SELECT RTRIM(CAMPO119) FROM INSERTED) = '' OR (SELECT RTRIM(CAMPO119) FROM INSERTED)='0'
BEGIN

-- DEFINIR TIPO DE COMISSÃO 

IF isnull((SELECT MAX(CAMPO49) FROM GEPRECTA  with (nolock) WHERE Tb_preco=@TABELA_PRECO AND Elemento=@ITEM),'0') <>'0'
	SET @TIPO_COMISSAO = 'T'
ELSE
	SET @TIPO_COMISSAO= 'A'

IF @TIPO_COMISSAO = 'A'
	BEGIN
		IF ISNULL((SELECT TOP(1)CD_TG FROM GEELEMEN  with (nolock) WHERE Elemento=@ITEM AND Cd_tg BETWEEN '300' AND '399'),'0')<>'0'
			SET @TIPO_COMISSAO = 'I'
		ELSE
			IF ISNULL((SELECT TOP(1)CD_TG FROM GEELEMEN with (nolock)WHERE Elemento=@REPR_EXT AND Cd_tg BETWEEN '300' AND '399'),'0')<>'0'
				SET @TIPO_COMISSAO = 'E'
			ELSE
				SET @TIPO_COMISSAO= 'A'	
	END

IF (SELECT Divisao FROM GEEMPRES  with (nolock) WHERE CD_EMPRESA=@REPR_EXT)='65' /*AND @TIPO_COMISSAO!='T'*/ 
	SET @TIPO_COMISSAO= 'C'	

IF ISNULL((SELECT TOP(1)CD_TG FROM GEELEMEN with (nolock)WHERE Elemento=@CLIENTE AND Cd_tg BETWEEN '300' AND '399'),'0')<>'0'
				SET @TIPO_COMISSAO = 'K'


PRINT @TIPO_COMISSAO

IF @TIPO_COMISSAO = 'A'
RETURN

-- PARA COMISSÃO C - CONFIGURAÇÃO, VENDEDOR FUNCIONÁRIO
IF @TIPO_COMISSAO = 'K'
	BEGIN
	SET @VL_ITEM = (SELECT Pr_unitario FROM inserted)
	SET @FAIXA_REP_EXT = ISNULL((SELECT TOP(1)LFFAIXA.Cd_codigo FROM LFFAIXA  with (nolock) WHERE SUBSTRING(LFFAIXA.Descricao,1,30)=(SELECT DESC_TG FROM GETG  with (nolock) WHERE CD_TG=(SELECT TOP(1)Cd_tg FROM GEELEMEN  with (nolock) WHERE Elemento=@CLIENTE AND Cd_tg BETWEEN '300' AND '399'))),'0') 
	
	SET @PE_REP_EXT = @PE_REP_EXT + ISNULL((SELECT DBO.RET_FAIXA_COMIS(@FAIXA_REP_EXT,isnull(@PE_DESC2,'0'))),'0')

	IF RTRIM(@REPR_EXT)!=''
		BEGIN
		INSERT INTO [GFCPE]
			   ([Pedido]           ,[Sequencia_Pedido]           ,[Representante]           ,[Base_Comissao]           ,[Comissao]           ,[Usuario_criacao]           ,[Usuario_modif]           ,[Dt_criacao]           ,[Dt_modif]           ,[Campo10]           ,[Campo11]           ,[Campo12]           ,[Campo13]           ,[Campo14]           ,[Campo15]           ,[Campo16]           ,[Campo17]           ,[Campo18]           ,[Campo19]           ,[Campo20])     
		VALUES (@PEDIDO           ,@SEQ_ITEM           ,@REPR_EXT           ,ISNULL((@BASE_COMIS),'0')           ,@PE_REP_EXT           ,(SELECT USUARIO_CRIACAO FROM INSERTED)           ,(SELECT USUARIO_CRIACAO FROM INSERTED)           ,(getdate())           ,(getdate())           ,''           ,''           ,'10'           ,'0'           ,'0'           ,'0'           ,null           ,null           ,'0'           ,'0'           ,'M'           )
        END	--INSERT REP_EXT
	IF RTRIM(@REPR_SUP)!=''
		BEGIN
		INSERT INTO [GFCPE]           ([Pedido]           ,[Sequencia_Pedido]           ,[Representante]           ,[Base_Comissao]           ,[Comissao]           ,[Usuario_criacao]           ,[Usuario_modif]           ,[Dt_criacao]           ,[Dt_modif]           ,[Campo10]           ,[Campo11]           ,[Campo12]           ,[Campo13]           ,[Campo14]           ,[Campo15]           ,[Campo16]           ,[Campo17]           ,[Campo18]           ,[Campo19]           ,[Campo20])
	    VALUES				          (@PEDIDO           ,@SEQ_ITEM           ,@REPR_SUP           ,ISNULL((@BASE_COMIS),'0')           ,@PE_REP_SUP           ,(SELECT USUARIO_CRIACAO FROM INSERTED)           ,(SELECT USUARIO_CRIACAO FROM INSERTED)           ,(getdate())           ,(getdate())           ,''           ,''           ,'10'           ,'0'           ,'0'           ,'0'           ,null           ,null           ,'0'           ,'0'           ,'M'           )
		END	--INSERT REP_SUP
	
	END
	
	
IF @TIPO_COMISSAO = 'C'
BEGIN
	SET @VL_ITEM = (SELECT Pr_unitario FROM inserted)
	SET @FAIXA_REP_EXT = ISNULL((SELECT TOP(1)LFFAIXA.Cd_codigo FROM LFFAIXA  with (nolock) WHERE SUBSTRING(LFFAIXA.Descricao,1,30)=(SELECT DESC_TG FROM GETG  with (nolock) WHERE CD_TG=(SELECT TOP(1)Cd_tg FROM GEELEMEN  with (nolock) WHERE Elemento=@REPR_EXT AND Cd_tg BETWEEN '300' AND '399'))),'0') 
	
	SET @PE_REP_EXT = @PE_REP_EXT + ISNULL((SELECT DBO.RET_FAIXA_COMIS(@FAIXA_REP_EXT,isnull(@PE_DESC2,'0'))),'0')

	IF RTRIM(@REPR_EXT)!=''
		BEGIN
		INSERT INTO [GFCPE]
			   ([Pedido]           ,[Sequencia_Pedido]           ,[Representante]           ,[Base_Comissao]           ,[Comissao]           ,[Usuario_criacao]           ,[Usuario_modif]           ,[Dt_criacao]           ,[Dt_modif]           ,[Campo10]           ,[Campo11]           ,[Campo12]           ,[Campo13]           ,[Campo14]           ,[Campo15]           ,[Campo16]           ,[Campo17]           ,[Campo18]           ,[Campo19]           ,[Campo20])     
		VALUES (@PEDIDO           ,@SEQ_ITEM           ,@REPR_EXT           ,ISNULL((@BASE_COMIS),'0')           ,@PE_REP_EXT           ,(SELECT USUARIO_CRIACAO FROM INSERTED)           ,(SELECT USUARIO_CRIACAO FROM INSERTED)           ,(getdate())           ,(getdate())           ,''           ,''           ,'10'           ,'0'           ,'0'           ,'0'           ,null           ,null           ,'0'           ,'0'           ,'M'           )
        END	--INSERT REP_EXT
	IF RTRIM(@REPR_SUP)!=''
		BEGIN
		INSERT INTO [GFCPE]           ([Pedido]           ,[Sequencia_Pedido]           ,[Representante]           ,[Base_Comissao]           ,[Comissao]           ,[Usuario_criacao]           ,[Usuario_modif]           ,[Dt_criacao]           ,[Dt_modif]           ,[Campo10]           ,[Campo11]           ,[Campo12]           ,[Campo13]           ,[Campo14]           ,[Campo15]           ,[Campo16]           ,[Campo17]           ,[Campo18]           ,[Campo19]           ,[Campo20])
	    VALUES				          (@PEDIDO           ,@SEQ_ITEM           ,@REPR_SUP           ,ISNULL((@BASE_COMIS),'0')           ,@PE_REP_SUP           ,(SELECT USUARIO_CRIACAO FROM INSERTED)           ,(SELECT USUARIO_CRIACAO FROM INSERTED)           ,(getdate())           ,(getdate())           ,''           ,''           ,'10'           ,'0'           ,'0'           ,'0'           ,null           ,null           ,'0'           ,'0'           ,'M'           )
		END	--INSERT REP_SUP
	
	END --COMISSAO E

-- PARA COMISSÃO T - TABELA DE PREÇO
IF @TIPO_COMISSAO = 'T'
	BEGIN
	SET @PE_REP_EXT = (SELECT MAX(CAMPO49) FROM GEPRECTA  with (nolock) WHERE Tb_preco=@TABELA_PRECO AND Elemento=@ITEM)

	IF RTRIM(@REPR_EXT)!=''
		BEGIN
		INSERT INTO [GFCPE]
			   ([Pedido]           ,[Sequencia_Pedido]           ,[Representante]           ,[Base_Comissao]           ,[Comissao]           ,[Usuario_criacao]           ,[Usuario_modif]           ,[Dt_criacao]           ,[Dt_modif]           ,[Campo10]           ,[Campo11]           ,[Campo12]           ,[Campo13]           ,[Campo14]           ,[Campo15]           ,[Campo16]           ,[Campo17]           ,[Campo18]           ,[Campo19]           ,[Campo20])     
		VALUES (@PEDIDO           ,@SEQ_ITEM           ,@REPR_EXT           ,ISNULL((@BASE_COMIS),'0')           ,@PE_REP_EXT           ,(SELECT USUARIO_CRIACAO FROM INSERTED)           ,(SELECT USUARIO_CRIACAO FROM INSERTED)           ,(getdate())           ,(getdate())           ,''           ,''           ,'10'           ,'0'           ,'0'           ,'0'           ,null           ,null           ,'0'           ,'0'           ,'M'           )
        END	--INSERT REP_EXT
	IF RTRIM(@REPR_SUP)!=''
		BEGIN
		INSERT INTO [GFCPE]           ([Pedido]           ,[Sequencia_Pedido]           ,[Representante]           ,[Base_Comissao]           ,[Comissao]           ,[Usuario_criacao]           ,[Usuario_modif]           ,[Dt_criacao]           ,[Dt_modif]           ,[Campo10]           ,[Campo11]           ,[Campo12]           ,[Campo13]           ,[Campo14]           ,[Campo15]           ,[Campo16]           ,[Campo17]           ,[Campo18]           ,[Campo19]           ,[Campo20])
	    VALUES				          (@PEDIDO           ,@SEQ_ITEM           ,@REPR_SUP           ,ISNULL((@BASE_COMIS),'0')           ,@PE_REP_SUP           ,(SELECT USUARIO_CRIACAO FROM INSERTED)           ,(SELECT USUARIO_CRIACAO FROM INSERTED)           ,(getdate())           ,(getdate())           ,''           ,''           ,'10'           ,'0'           ,'0'           ,'0'           ,null           ,null           ,'0'           ,'0'           ,'M'           )
		END	--INSERT REP_SUP
	
	END --COMISSAO T


-- PARA COMISSÃO TIPO E - TG NA EMPRESA/REPRESENTANTE

IF @TIPO_COMISSAO in ('E')
	BEGIN
	SET @VL_ITEM = (SELECT Pr_unitario FROM inserted)
	SET @FAIXA_REP_EXT = ISNULL((SELECT TOP(1)LFFAIXA.Cd_codigo FROM LFFAIXA  with (nolock) WHERE SUBSTRING(LFFAIXA.Descricao,1,30)=(SELECT DESC_TG FROM GETG  with (nolock) WHERE CD_TG=(SELECT TOP(1)Cd_tg FROM GEELEMEN  with (nolock) WHERE Elemento=@REPR_EXT AND Cd_tg BETWEEN '300' AND '399'))),'0') 
	
	SET @PE_REP_EXT = @PE_REP_EXT + ISNULL((SELECT DBO.RET_FAIXA_COMIS(@FAIXA_REP_EXT,isnull(@PE_DESC2,'0'))),'0')

	IF RTRIM(@REPR_EXT)!=''
		BEGIN
		INSERT INTO [GFCPE]
			   ([Pedido]           ,[Sequencia_Pedido]           ,[Representante]           ,[Base_Comissao]           ,[Comissao]           ,[Usuario_criacao]           ,[Usuario_modif]           ,[Dt_criacao]           ,[Dt_modif]           ,[Campo10]           ,[Campo11]           ,[Campo12]           ,[Campo13]           ,[Campo14]           ,[Campo15]           ,[Campo16]           ,[Campo17]           ,[Campo18]           ,[Campo19]           ,[Campo20])     
		VALUES (@PEDIDO           ,@SEQ_ITEM           ,@REPR_EXT           ,ISNULL((@BASE_COMIS),'0')           ,@PE_REP_EXT           ,(SELECT USUARIO_CRIACAO FROM INSERTED)           ,(SELECT USUARIO_CRIACAO FROM INSERTED)           ,(getdate())           ,(getdate())           ,''           ,''           ,'10'           ,'0'           ,'0'           ,'0'           ,null           ,null           ,'0'           ,'0'           ,'M'           )
        END	--INSERT REP_EXT
	IF RTRIM(@REPR_SUP)!=''
		BEGIN
		INSERT INTO [GFCPE]           ([Pedido]           ,[Sequencia_Pedido]           ,[Representante]           ,[Base_Comissao]           ,[Comissao]           ,[Usuario_criacao]           ,[Usuario_modif]           ,[Dt_criacao]           ,[Dt_modif]           ,[Campo10]           ,[Campo11]           ,[Campo12]           ,[Campo13]           ,[Campo14]           ,[Campo15]           ,[Campo16]           ,[Campo17]           ,[Campo18]           ,[Campo19]           ,[Campo20])
	    VALUES				          (@PEDIDO           ,@SEQ_ITEM           ,@REPR_SUP           ,ISNULL((@BASE_COMIS),'0')           ,@PE_REP_SUP           ,(SELECT USUARIO_CRIACAO FROM INSERTED)           ,(SELECT USUARIO_CRIACAO FROM INSERTED)           ,(getdate())           ,(getdate())           ,''           ,''           ,'10'           ,'0'           ,'0'           ,'0'           ,null           ,null           ,'0'           ,'0'           ,'M'           )
		END	--INSERT REP_SUP
	
	END --COMISSAO E


-- PARA COMISSÕES DO TIPO I - TG NO ITEM
IF @TIPO_COMISSAO in ('I')
	BEGIN

	SET @VL_ITEM = (SELECT Pr_unitario FROM inserted)
	SET @FAIXA_REP_EXT = ISNULL((SELECT TOP(1)LFFAIXA.Cd_codigo FROM LFFAIXA  with (nolock) WHERE SUBSTRING(LFFAIXA.Descricao,1,30)=(SELECT DESC_TG FROM GETG  with (nolock) WHERE CD_TG=(SELECT TOP(1)Cd_tg FROM GEELEMEN  with (nolock) WHERE Elemento=@ITEM AND Cd_tg BETWEEN '300' AND '399'))),'0')
	
	SET @PE_REP_EXT = @PE_REP_EXT + ISNULL((SELECT DBO.RET_FAIXA_COMIS(@FAIXA_REP_EXT,isnull(@PE_DESC2,'0'))),'0')
	PRINT @VL_ITEM 
	PRINT @FAIXA_REP_EXT
	PRINT @PE_DESC2
	IF RTRIM(@REPR_EXT)!=''
		BEGIN
		INSERT INTO [GFCPE]
			   ([Pedido]           ,[Sequencia_Pedido]           ,[Representante]           ,[Base_Comissao]           ,[Comissao]           ,[Usuario_criacao]           ,[Usuario_modif]           ,[Dt_criacao]           ,[Dt_modif]           ,[Campo10]           ,[Campo11]           ,[Campo12]           ,[Campo13]           ,[Campo14]           ,[Campo15]           ,[Campo16]           ,[Campo17]           ,[Campo18]           ,[Campo19]           ,[Campo20])     
		VALUES (@PEDIDO           ,@SEQ_ITEM           ,@REPR_EXT           ,ISNULL((@BASE_COMIS),'0')           ,@PE_REP_EXT           ,(SELECT USUARIO_CRIACAO FROM INSERTED)           ,(SELECT USUARIO_CRIACAO FROM INSERTED)           ,(getdate())           ,(getdate())           ,''           ,''           ,'10'           ,'0'           ,'0'           ,'0'           ,null           ,null           ,'0'           ,'0'           ,'M'           )
        END	--INSERT REP_EXT
	IF RTRIM(@REPR_SUP)!=''
		BEGIN
		INSERT INTO [GFCPE]           ([Pedido]           ,[Sequencia_Pedido]           ,[Representante]           ,[Base_Comissao]           ,[Comissao]           ,[Usuario_criacao]           ,[Usuario_modif]           ,[Dt_criacao]           ,[Dt_modif]           ,[Campo10]           ,[Campo11]           ,[Campo12]           ,[Campo13]           ,[Campo14]           ,[Campo15]           ,[Campo16]           ,[Campo17]           ,[Campo18]           ,[Campo19]           ,[Campo20])
	    VALUES				          (@PEDIDO           ,@SEQ_ITEM           ,@REPR_SUP           ,ISNULL((@BASE_COMIS),'0')           ,@PE_REP_SUP           ,(SELECT USUARIO_CRIACAO FROM INSERTED)           ,(SELECT USUARIO_CRIACAO FROM INSERTED)           ,(getdate())           ,(getdate())           ,''           ,''           ,'10'           ,'0'           ,'0'           ,'0'           ,null           ,null           ,'0'           ,'0'           ,'M'           )
		END	--INSERT REP_SUP
	
	END --COMISSAO I
END
END
GO

