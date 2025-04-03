SELECT
	FTB.DataEmissaoNotaFiscal,
	dEstab.CodEstab,
	FTB.SerieNotaFiscal,
	FTB.NumeroNotaFiscal,           
	FTB.NumeroNotaRemessa,
	FTB.NomeTransp,
	FTB.IdEmitente,
	dEmi.NomeMatriz AS Matriz,
	CAST(FTB.QuantidadeFaturada AS FLOAT) AS QuantidadeFaturada,
	CAST(COALESCE(FTB.QuantidadeDevolvida, 0) AS FLOAT) AS QuantidadeDevolvida,
	CAST(COALESCE(FTB.QuantidadeAbatida, FTB.QuantidadeFaturada) AS FLOAT) AS QuantidadeAbatida,
	CAST(FTB.ValorUnitario AS FLOAT) AS ValorUnitario,
	CAST(FTB.[ValorNotaFiscal] AS FLOAT) AS ValorNotaFiscal,
	CAST(COALESCE(FTB.ValorDevolvido, 0) AS FLOAT) AS ValorDevolvido,
	CAST(COALESCE(FTB.ValorAbatido, FTB.ValorNotaFiscal) AS FLOAT) AS ValorAbatido,

	CASE
		WHEN FTB.DataSaida = '1900-01-01' THEN NULL
		ELSE FTB.DataSaida
	END AS DataSaida,

	FTB.Observacao,
	FTB.ObservacaoExpedicao,
	UPPER(FTB.Deposito) AS Deposito,
	CASE dEmi.Agenda
		WHEN 1 THEN 'Com'
		ELSE 'Sem'
	END AS Agenda,
	FTB.Frete,

	CASE
		WHEN dItem.CodLinhaPai = 1 THEN 100
		WHEN dItem.CodLinhaPai = 4 THEN 200
		WHEN dItem.CodLinhaPai = 7 THEN 300
		WHEN dItem.CodLinhaPai = 8 THEN 400
		ELSE NULL
	END AS CodLinhaPai,

	(CASE
		WHEN FTB.DataPrimeiraTratativaAgenda = '1900-01-01' THEN NULL
		ELSE FTB.DataPrimeiraTratativaAgenda
	END) AS DataPrimeiraTratativaAgenda,

	CASE
		WHEN FTB.[StatusLogistica] = 'DEVOLUÇÃO' THEN 'Em processo de devolução' 
		WHEN FTB.[StatusLogistica] LIKE 'REAGENDADO%' AND FTB.[DataReagenda] > GETDATE() AND FTB.[StatusPainel] = 'Agendado' THEN 'Reagendado - Em Trânsito'
		ELSE FTB.[StatusSistemico]
	END AS StatusSistemico,
	CASE
		WHEN FTB.[StatusPainel] = 'Pendência' THEN 'Pendência Comercial' 
		WHEN FTB.[StatusLogistica] = 'DEVOLUÇÃO' THEN 'Pendência Logística'
		ELSE FTB.[StatusPainel]
	END AS StatusPainel,
	CASE
		WHEN DataSaida IS NULL THEN 'Não'
		ELSE 'Sim'
	END AS 'Embarcado?',
	CASE
		WHEN TipoCarga IS NULL THEN 'Fracionado'
		WHEN LEFT(TipoCarga, 1) IN ('C', 'T', '?') THEN 'Lotação'
		ELSE 'Fracionado'
	END AS 'Tipo Carga',
	CASE
		WHEN DataEntrega IS NULL THEN 'Não'
		ELSE 'Sim'
	END AS 'Entregue?',
	FTB.StatusLogistica,
	dEmi.CodCD AS CD
	 
FROM logistica.Fato_FTB105 FTB WITH(NOLOCK)

LEFT  JOIN auditoria.Fato_CustosFrete_Faturamento CFT WITH(NOLOCK) -- LEFT pois nem toda nota 'Entregue', existe na CFT
		ON CFT.IdEstab = FTB.IdEstab 
		AND CFT.SerieNotaFiscal = FTB.SerieNotaFiscal
		AND CFT.NumeroNotaFiscal = FTB.NumeroNotaFiscal
LEFT  JOIN Dim_Data dData WITH(NOLOCK)
		ON dData.Id = CFT.IdDataPrevisEntrega

INNER JOIN dbo.Dim_Estabelecimento dEstab WITH(NOLOCK) 
		ON dEstab.Id = FTB.IdEstab
INNER JOIN dbo.Dim_Item dItem WITH(NOLOCK) 
		ON dItem.Id = FTB.IdItem
INNER JOIN dbo.Dim_Emitente dEmi WITH(NOLOCK) 
		ON dEmi.IdEmitente = FTB.IdEmitente

WHERE 1=1
  AND dItem.CodLinha NOT IN (11)
  AND FTB.DataEntrega IS NULL -- Notas Não entregue
  AND FTB.DataEmissaoNotaFiscal >= '01/12/2024'
  AND FTB.SerieNotaFiscal IN (1,10,12,17,41,52,76)
  AND CONVERT(VARCHAR, dEstab.CodEstab) IN ('15','22','31','128','130')
