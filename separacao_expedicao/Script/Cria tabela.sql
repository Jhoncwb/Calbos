drop TABLE [dbo].[LC_BARRAS]
CREATE TABLE [dbo].[LC_BARRAS](
	[cd_barras] [int] IDENTITY(1,1) NOT NULL,
	[op] [int] NOT NULL,
	[cd_material] [char](20) NOT NULL,
	[impresso] [bit] NOT NULL,
	[tp_barras_usado] [bit] NOT NULL,
	[cd_barras_usado] [bit] NOT NULL,
	[movimento_producao] [int] NOT NULL,
	[pedido] [char] (12) NOT NULL,
	[sequencia] [int] NOT NULL,
	[volume] [int] NOT NULL,
	[quantidade] [float] NOT NULL,
	[usuario] [char](3) NOT NULL
) ON [PRIMARY]


