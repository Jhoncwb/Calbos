CREATE PROCEDURE [dbo].[sp_Relatorio_Entrada] @op_inicial int,@op_final int
AS
begin

DECLARE 
	@v_cd_material char(20),
	@v_op int,
	@v_Quantidade float,
	@v_count float
	
	DECLARE Atualiza_empresa CURSOR FOR
		  SELECT ESMATERI.cd_material, PCORPROD.Especif1, PCORPROD.OP, PCORPROD.Quantidade FROM PCORPROD inner join ESMATERI on ESMATERI.Cd_material = PCORPROD.Cd_material where not exists (select * from spar_cd_barras where spar_cd_barras.op = PCORPROD.OP and spar_cd_barras.cd_material = PCORPROD.Cd_material and spar_cd_barras.especif1 = PCORPROD.Especif1);
	  OPEN Atualiza_empresa
	  FETCH Atualiza_empresa INTO @v_cd_material, @v_op, @v_Quantidade
	  WHILE(@@fetch_status = 0)
	  BEGIN
		set @v_count = 0;
		while (@v_count < @v_Quantidade)
		begin
			INSERT INTO [dbo].[LC_BARRAS] VALUES (@v_op,@v_cd_material,@v_Especif1,0,0,' ',0)
			set @v_count = @v_count + (SELECT campo7 FROM ESMATERI where esmateri.Cd_material = @v_cd_material) ;
		end
		FETCH Atualiza_empresa INTO @v_cd_material, @v_Especif1, @v_op, @v_Quantidade
	  END
	CLOSE Atualiza_empresa
DEALLOCATE Atualiza_empresa;

--select
SELECT 
(rtrim (ESMATERI.Descricao) + ' ' + 
rtrim(dbo.RETORNA_CARACT_IDENTIFICADOR(ESMATERI.Cd_material,PCORPROD.especif1,'001')) + ' ' +
rtrim(dbo.RETORNA_CARACT_IDENTIFICADOR(ESMATERI.Cd_material,PCORPROD.especif1,'002')) + ' ' +
rtrim(dbo.RETORNA_CARACT_IDENTIFICADOR(ESMATERI.Cd_material,PCORPROD.especif1,'003')) + ' ' +
rtrim(dbo.RETORNA_CARACT_IDENTIFICADOR(ESMATERI.Cd_material,PCORPROD.especif1,'004')) + ' ' +
rtrim(dbo.RETORNA_CARACT_IDENTIFICADOR(ESMATERI.Cd_material,PCORPROD.especif1,'005')) + ' ' +
rtrim(dbo.RETORNA_CARACT_IDENTIFICADOR(ESMATERI.Cd_material,PCORPROD.especif1,'006'))) as 'DESCRICAO',
rtrim(dbo.RETORNA_CARACT_IDENTIFICADOR(ESMATERI.Cd_material,PCORPROD.especif1,'007')) AS 'NUMERAÇÃO',
ESMATERI.cd_material as 'Cod_Material',
PCORPROD.Especif1,
PCORPROD.OP,
PCORPROD.Quantidade,
SPAR_CD_BARRAS.cd_barras

FROM PCORPROD 
inner join ESMATERI on ESMATERI.Cd_material = PCORPROD.Cd_material
inner join SPAR_CD_BARRAS on SPAR_CD_BARRAS.op = PCORPROD.OP

Where PCORPROD.OP between @op_inicial and @op_final

end
GO





select EMBALAGEM.Cd_material, EMBALAGEM.Descricao, * 
from ESMATERI
inner join PEENGENH on ESMATERI.Cd_material = PEENGENH.Cd_pai
inner join ESMATERI EMBALAGEM ON EMBALAGEM.Cd_material = PEENGENH.Cd_recurso_insu AND EMBALAGEM.Cd_grupo = 'ME' and EMBALAGEM.Cd_sub_grupo = 'CXP'

