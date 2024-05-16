ALTER TRIGGER [dbo].[SPAR_AJUSTA_PERC_COMISS] ON [dbo].[GFCOMISS]

AFTER INSERT, UPDATE

AS

declare
	@P_Comiss_geral float,
	@VL_COMISSAO FLOAT,
	@TOTAL_FINANCEIRO FLOAT


IF TRIGGER_NESTLEVEL()>3
	RETURN

SELECT @VL_COMISSAO = (sum(base_comissao * comissao / 100))
FROM GFCNF
WHERE NF = (SELECT NF FROM GFLANCAM where Cd_lancamento = (select Cd_lancamento from inserted) )
AND UN = (SELECT Cd_unidade_de_n FROM GFLANCAM where Cd_lancamento = (select Cd_lancamento from inserted) )
AND Representante = (select Representante from inserted);

SELECT @TOTAL_FINANCEIRO = Total_nf
FROM FANFISCA 
WHERE FANFISCA.NF = (SELECT NF FROM GFLANCAM where Cd_lancamento = (select Cd_lancamento from inserted) )
AND FANFISCA.Serie = (SELECT Serie FROM GFLANCAM where Cd_lancamento = (select Cd_lancamento from inserted) )
and FANFISCA.Cd_unidade_de_n = (SELECT Cd_unidade_de_n FROM GFLANCAM where Cd_lancamento = (select Cd_lancamento from inserted) )
AND  FANFISCA.Cd_cliente = (SELECT Cd_empresa FROM GFLANCAM where Cd_lancamento = (select Cd_lancamento from inserted) );

set @P_Comiss_geral = @VL_COMISSAO/@TOTAL_FINANCEIRO*100
if not exists (select * from gflancam where  gflancam.cd_lancamento in (select cd_lancamento from inserted) and 
(gflancam.Cd_tipo_de_paga in ('90') or gflancam.cd_portador in ('X51')))
update GFCOMISS set percentual_comi = isnull(@P_Comiss_geral,0) where cd_lancamento in (select cd_lancamento from inserted);





