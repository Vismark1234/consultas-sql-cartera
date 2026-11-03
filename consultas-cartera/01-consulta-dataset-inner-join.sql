/* DATASET DE CARTERA CON INNER JOIN DE CLIENTES */

SET NOCOUNT ON;
SET XACT_ABORT ON;

/* 1. PARAMETROS */

DECLARE @FechaInicio DATE = EOMONTH(DATEFROMPARTS(2026, 8, 1));
DECLARE @FechaFin DATE = EOMONTH(DATEFROMPARTS(2026, 8, 1));
DECLARE @MostrarDataset BIT = 0; -- Cambiar a 1 solo si se desea mostrar/exportar todo.

IF @FechaInicio > @FechaFin
    THROW 50001, 'FechaInicio no puede ser mayor que FechaFin.', 1;

DROP TABLE IF EXISTS #Meses;

CREATE TABLE #Meses
(
    FechaCorte DATE NOT NULL PRIMARY KEY
);

DECLARE @Mes DATE = @FechaInicio;

WHILE @Mes <= @FechaFin
BEGIN
    INSERT INTO #Meses (FechaCorte) VALUES (@Mes);
    SET @Mes = EOMONTH(DATEADD(MONTH, 1, @Mes));
END;


/* 2. CLIENTES DEL RANGO */

DROP TABLE IF EXISTS #ClienteUnico;

;WITH ClienteOrdenado AS
(
    SELECT
        ClienteKey,
        FechaCorte,
        Edad,
        Genero,
        EstadoCivil,
        NumeroHijos,
        Ciudad,
        Departamento,
        Barrio,
        edadComoClienteMeses,
        Segmento,
        Nacionalidad,
        JefaHogar,
        NivelIngreso,
        NivelEgreso,
        TipoFuenteIngreso,
        Profesion,
        GradoInstruccion,
        EsDeudorcartera,
        EsCodeudorcartera,
        EsGarantecartera,
        EsClienteActivoDigital,
        EsclienteTinka,
        ROW_NUMBER() OVER
        (
            PARTITION BY ClienteKey, FechaCorte
            ORDER BY
                CASE WHEN Asignacion_Motivo = 'cartera' THEN 0 ELSE 1 END,
                Asignacion_Motivo
        ) AS rn
    FROM Resultados.dcli.dominioclientes
    WHERE FechaCorte BETWEEN @FechaInicio AND @FechaFin
      AND TipoPersona = 'PERSONA NATURAL'
)
SELECT
    ClienteKey,
    FechaCorte,
    Edad,
    Genero,
    EstadoCivil,
    NumeroHijos,
    Ciudad,
    Departamento,
    Barrio,
    edadComoClienteMeses,
    Segmento,
    Nacionalidad,
    JefaHogar,
    NivelIngreso,
    NivelEgreso,
    TipoFuenteIngreso,
    Profesion,
    GradoInstruccion,
    EsDeudorcartera,
    EsCodeudorcartera,
    EsGarantecartera,
    EsClienteActivoDigital,
    EsclienteTinka
INTO #ClienteUnico
FROM ClienteOrdenado
WHERE rn = 1;

CREATE UNIQUE CLUSTERED INDEX IX_ClienteUnico
    ON #ClienteUnico (FechaCorte, ClienteKey);


/* 3. HISTORICO TRANSACCIONAL */

DROP TABLE IF EXISTS #HistoricoTransaccional;

SELECT
    m.FechaCorte,
    ClienteKey,
    CantidadTrx_3M,
    MontoTotalBs_3M,
    CantidadDepositos_3M,
    CantidadRetiros_3M,
    MontoDepositosBs_3M,
    MontoRetirosBs_3M,
    CantidadTrx_6M,
    MontoTotalBs_6M,
    CantidadDepositos_6M,
    CantidadRetiros_6M,
    MontoDepositosBs_6M,
    MontoRetirosBs_6M,
    CantidadTrx_12M,
    MontoTotalBs_12M,
    CantidadDepositos_12M,
    CantidadRetiros_12M,
    MontoDepositosBs_12M,
    MontoRetirosBs_12M,
    MesesConHistoria
INTO #HistoricoTransaccional
FROM #Meses m
CROSS APPLY test.dbo.fn_DominioMensual(m.FechaCorte) AS h;

CREATE INDEX IX_HistoricoTransaccional_Cliente
    ON #HistoricoTransaccional (FechaCorte, ClienteKey);


/* 4. EVENTOS DEL RANGO */

DROP TABLE IF EXISTS #EventosFecha;

SELECT
    Evento,
    DuracionDias,
    CodigoRegional,
    CodigoDepartamento,
    Descripcion,
    FechaInicio,
    FechaFin
INTO #EventosFecha
FROM
(
    SELECT
        Evento,
        DuracionDias,
        CodigoRegional,
        CodigoDepartamento,
        Descripcion,
        TRY_CONVERT(DATE, FechaInicio, 103) AS FechaInicio,
        TRY_CONVERT(DATE, FechaFin, 103) AS FechaFin
    FROM Inteligencia_Comercial.dbo.EventosRelevantes
) e
WHERE e.FechaInicio <= @FechaFin
  AND e.FechaFin >= @FechaInicio;

CREATE INDEX IX_EventosFecha_Regional
    ON #EventosFecha (CodigoRegional, FechaInicio, FechaFin);


/* 5. DATASET FINAL */

DROP TABLE IF EXISTS #Dataset;

SELECT
    car.FechaCorte                              AS FechaCorte,
    car.CarteraKey                              AS CarteraKey,
    car.ClienteKey                              AS ClienteKey,

    -- Perfil del cliente
    cli.Edad                                    AS EdadCliente,
    cli.Genero                                  AS GeneroCliente,
    cli.EstadoCivil                             AS EstadoCivilCliente,
    cli.NumeroHijos                             AS NumeroHijosCliente,
    cli.Ciudad                                  AS CiudadCliente,
    cli.Departamento                            AS DepartamentoCliente,
    cli.Barrio                                  AS BarrioCliente,
    cli.edadComoClienteMeses                    AS AntiguedadClienteMeses,
    cli.Segmento                                AS SegmentoCliente,
    cli.Nacionalidad                            AS NacionalidadCliente,
    cli.JefaHogar                               AS EsJefaHogar,

    -- Situacion economica
    cli.NivelIngreso                            AS NivelIngresoCliente,
    cli.NivelEgreso                             AS NivelEgresoCliente,
    cli.TipoFuenteIngreso                       AS FuenteIngresoCliente,
    cli.Profesion                               AS ProfesionCliente,
    cli.GradoInstruccion                        AS GradoInstruccionCliente,
    car.Patrimonio                              AS PatrimonioClienteBs,
    car.Activos                                 AS ActivosClienteBs,
    car.VentasAnuales                           AS VentasAnualesClienteBs,

    -- Endeudamiento externo
    inf.PeorCalificacionASFIKey                 AS InfocredPeorCalificacionASFIKey,
    inf.SaldoVigenteBs                          AS InfocredSaldoVigenteBs,
    inf.SaldoVencidoBs                          AS InfocredSaldoVencidoBs,
    inf.SaldoEjecucionBs                        AS InfocredSaldoEjecucionBs,
    inf.SaldoCantigadoBs                        AS InfocredSaldoCastigadoBs,
    inf.SaldoContingenteBs                      AS InfocredSaldoContingenteBs,
    DATEDIFF(MONTH, car.FechaCorte, inf.MaximaFechaVencimiento)
                                                  AS InfocredMesesHastaMaxVencimiento,
    inf.MontoDeudaTotalBs                       AS InfocredMontoDeudaTotalBs,
    inf.CuotaBs                                 AS InfocredCuotaBs,
    inf.CantidadDeudasOtrasEntidades            AS InfocredCantDeudasOtrasEntidades,
    inf.CantidadDeudasDeudor                    AS InfocredCantDeudasDeudor,
    inf.CantidadDeudasCodeudor                  AS InfocredCantDeudasCodeudor,
    inf.EsCreditoVivienda                       AS InfocredEsCreditoVivienda,

    -- Productos y canales
    car.Productocartera                         AS ProductoCartera,
    cli.EsDeudorcartera                         AS EsDeudorCartera,
    cli.EsCodeudorcartera                       AS EsCodeudorCartera,
    cli.EsGarantecartera                        AS EsGaranteCartera,
    cli.EsClienteActivoDigital                  AS EsClienteDigital,
    cli.EsclienteTinka                          AS EsClienteTinka,

    -- Caracteristicas del credito
    car.CodigoOficialCredito                    AS CodigoOficialCredito,
    car.NombreOficialCredito                    AS NombreOficialCredito,
    car.TipoCredito                             AS TipoCredito,
    car.TipoBanca                               AS TipoBanca,
    car.TasaEfectiva                            AS TasaEfectivaCredito,
    car.TasaBase                                AS TasaBaseCredito,
    car.TasaTRE                                 AS TasaTRECredito,
    car.PlazoDias                               AS PlazoCreditoDias,
    car.PlazoMeses                              AS PlazoCreditoMeses,
    car.FrecuenciaPago                          AS FrecuenciaPagoCredito,
    car.TipoAmortizacion                        AS TipoAmortizacion,
    car.CantidadReprogramaciones                AS CantidadReprogramaciones,
    car.MontoReprogramadoBs                     AS MontoReprogramadoBs,
    car.EstadoCredito                           AS EstadoCredito,
    car.LineaCredito                            AS LineaCredito,
    car.MontoLineaCreditoBs                     AS MontoLineaCreditoBs,

    -- Actividad economica
    car.SectorEconomicoCliente                  AS SectorEconomicoCliente,
    car.SectorEconomicoCredito                  AS SectorEconomicoCredito,
    car.ActividadEconomicaCliente               AS ActividadEconomicaCliente,
    car.ActividadEconomicaCredito               AS ActividadEconomicaCredito,
    car.ActividadEconomicaClienteCAEDEC         AS ActividadEconomicaClienteCAEDEC,
    car.ActividadEconomicaCreditoCAEDEC         AS ActividadEconomicaCreditoCAEDEC,
    car.Nrotrabajadores                         AS NumeroTrabajadores,
    car.IndiceActividad                         AS IndiceActividadEconomica,
    car.TamanioEmpresa                          AS TamanioEmpresa,

    -- Endeudamiento y garantias
    car.SaldoBs                                 AS SaldoCreditoBs,
    car.SaldoCapitalBs                          AS SaldoCapitalBs,
    car.SaldoDiferidoBs                         AS SaldoDiferidoBs,
    car.InteresBs                               AS InteresBs,
    car.OtrosRubrosBs                           AS OtrosRubrosBs,
    car.MontoDesembolsadoBs                     AS MontoDesembolsadoBs,
    car.GarantiaHipotecaria                     AS GarantiaHipotecariaBs,
    car.GarantiaPersonal                        AS GarantiaPersonalBs,
    car.GarantiaPrendaria                       AS GarantiaPrendariaBs,
    car.GarantiaCaptacion                       AS GarantiaCaptacionBs,
    car.GarantiaOtros                           AS GarantiaOtrosBs,
    car.GarantiaDocumentosCustodia              AS GarantiaDocumentosCustodiaBs,
    car.MontoGarantiaBs                         AS MontoGarantiaTotalBs,
    car.PrevisionRequeridaBs                    AS PrevisionRequeridaBs,
    car.PrevisionCiclicaBs                      AS PrevisionCiclicaBs,

    -- Fechas del credito
    DATEDIFF(MONTH, car.FechaCorte, car.FechaVencimiento)
                                                  AS MesesHastaVencimientoCredito,
    car.FechaVencimiento                        AS FechaVencimiento,
    DATEDIFF(MONTH, car.FechaCorte, car.FechaVencimientoReprogramada)
                                                  AS MesesHastaVencimientoReprogramado,
    car.FechaVencimientoReprogramada            AS FechaVencimientoReprogramada,
    DATEDIFF(MONTH, car.FechaCorte, car.FechaRefinanciamiento)
                                                  AS MesesDiferenciaRefinanciamiento,
    car.FechaRefinanciamiento                   AS FechaRefinanciamiento,
    DATEDIFF(DAY, car.FechaCorte, car.FechaProximoPago)
                                                  AS DiasHastaProximoPago,
    car.FechaProximoPago                        AS FechaProximoPago,

    -- Eventos
    eve.Evento                                  AS Evento,
    eve.DuracionDias                            AS EventoDuracionDias,
    eve.CodigoRegional                          AS EventoCodigoRegional,
    eve.CodigoDepartamento                      AS EventoCodigoDepartamento,
    eve.Descripcion                             AS EventoDescripcion,

    -- Comportamiento de pago
    car.MaxDiasMoraMes                          AS MaxDiasMoraMes,
    car.MaxDiasMora3M                           AS MaxDiasMora3M,
    car.PromedioMora3M                          AS PromedioMora3M,
    car.MesesConMora3M                          AS MesesConMora3M,
    car.MaxDiasMora6M                           AS MaxDiasMora6M,
    car.PromedioMora6M                          AS PromedioMora6M,
    car.MesesConMora6M                          AS MesesConMora6M,
    car.MaxDiasMora12M                          AS MaxDiasMora12M,
    car.PromedioMora12M                         AS PromedioMora12M,
    car.MesesConMora12M                         AS MesesConMora12M,
    car.TasaCumplimiento                        AS TasaCumplimiento,
    car.AntiguedadCreditoMeses                  AS AntiguedadCreditoMeses,
    car.CalificacionFIE                         AS CalificacionFIE,
    car.CalificacionASFI                        AS CalificacionASFI,

    -- Comportamiento transaccional del mes
    tra.CantidadTrx                             AS CantidadTrx,
    tra.MontoTotalBs                            AS MontoTotalTrxBs,
    tra.CantidadDepositos                       AS CantidadDepositos,
    tra.CantidadRetiros                         AS CantidadRetiros,
    tra.MontoDepositosBs                        AS MontoDepositosBs,
    tra.MontoRetirosBs                          AS MontoRetirosBs,
    tra.FlujoNetoBs                             AS FlujoNetoBs,
    tra.CantidadQR                              AS CantidadQR,
    tra.CantidadDigital                         AS CantidadDigital,
    tra.CantidadPresencial                      AS CantidadPresencial,
    tra.CantidadAutoservicio                    AS CantidadAutoservicio,
    tra.CantidadProcesamiento                   AS CantidadProcesamiento,
    tra.MontoQR                                 AS MontoQRBs,
    tra.MontoDigital                            AS MontoDigitalBs,
    tra.MontoPresencial                         AS MontoPresencialBs,
    tra.MontoAutoservicio                       AS MontoAutoservicioBs,
    tra.MontoProcesamiento                      AS MontoProcesamientoBs,

    -- Historico transaccional de 3 meses
    trh.CantidadTrx_3M                          AS CantidadTrx3M,
    trh.MontoTotalBs_3M                         AS MontoTotalBs3M,
    trh.CantidadDepositos_3M                    AS CantidadDepositos3M,
    trh.CantidadRetiros_3M                      AS CantidadRetiros3M,
    trh.MontoDepositosBs_3M                     AS MontoDepositosBs3M,
    trh.MontoRetirosBs_3M                       AS MontoRetirosBs3M,

    -- Historico transaccional de 6 meses
    trh.CantidadTrx_6M                          AS CantidadTrx6M,
    trh.MontoTotalBs_6M                         AS MontoTotalBs6M,
    trh.CantidadDepositos_6M                    AS CantidadDepositos6M,
    trh.CantidadRetiros_6M                      AS CantidadRetiros6M,
    trh.MontoDepositosBs_6M                     AS MontoDepositosBs6M,
    trh.MontoRetirosBs_6M                       AS MontoRetirosBs6M,

    -- Historico transaccional de 12 meses
    trh.CantidadTrx_12M                         AS CantidadTrx12M,
    trh.MontoTotalBs_12M                        AS MontoTotalBs12M,
    trh.CantidadDepositos_12M                   AS CantidadDepositos12M,
    trh.CantidadRetiros_12M                     AS CantidadRetiros12M,
    trh.MontoDepositosBs_12M                    AS MontoDepositosBs12M,
    trh.MontoRetirosBs_12M                      AS MontoRetirosBs12M,
    trh.MesesConHistoria                        AS MesesConHistoria,

    -- Indicadores de cobertura de los JOIN
    CONVERT(BIT, CASE WHEN tra.ClienteKey IS NULL THEN 0 ELSE 1 END)
                                                  AS TieneTransaccionesMes,
    CONVERT(BIT, CASE WHEN trh.ClienteKey IS NULL THEN 0 ELSE 1 END)
                                                  AS TieneHistoricoTransaccional,
    CONVERT(BIT, CASE WHEN inf.ClienteKey IS NULL THEN 0 ELSE 1 END)
                                                  AS TieneInfocred,
    CONVERT(BIT, CASE WHEN eve.CodigoRegional IS NULL THEN 0 ELSE 1 END)
                                                  AS TieneEvento
INTO #Dataset
FROM Resultados.dcar.dominiocartera car
INNER JOIN #ClienteUnico cli
        ON cli.ClienteKey = car.ClienteKey
       AND cli.FechaCorte = car.FechaCorte
LEFT JOIN Inteligencia_Comercial.dbo.TransaccionesMensuales tra
       ON tra.ClienteKey = car.ClienteKey
      AND tra.Fecha = car.FechaCorte
LEFT JOIN #HistoricoTransaccional trh
       ON trh.ClienteKey = car.ClienteKey
      AND trh.FechaCorte = car.FechaCorte
LEFT JOIN Inteligencia_Comercial.dbo.clienteinfocred inf
       ON inf.ClienteKey = car.ClienteKey
      AND inf.FechaKey = CONVERT(INT, CONVERT(CHAR(8), car.FechaCorte, 112))
LEFT JOIN #EventosFecha eve
       ON eve.CodigoRegional = car.CodigoRegional
      AND car.FechaCorte BETWEEN eve.FechaInicio AND eve.FechaFin
WHERE car.FechaCorte BETWEEN @FechaInicio AND @FechaFin
  AND car.Producto = 'CARTERA'
  AND car.TipoBanca = 'BANCA MICROEMPRESA'
  AND car.EstadoCredito = 'VIGENTE'
  AND car.FrecuenciaPago = 'MENSUAL';

CREATE INDEX IX_Dataset_CarteraKey
    ON #Dataset (CarteraKey);


/* 6. MOSTRAR EL DATASET */

IF @MostrarDataset = 1
BEGIN
    SELECT *
    FROM #Dataset;
END;


/* 7. CONVERSION DE FECHAS DE EVENTOS */

/*
SELECT
    FechaInicio AS FechaInicioOriginal,
    TRY_CONVERT(DATE, FechaInicio, 103) AS FechaInicioDate,
    FechaFin AS FechaFinOriginal,
    TRY_CONVERT(DATE, FechaFin, 103) AS FechaFinDate
FROM Inteligencia_Comercial.dbo.EventosRelevantes;
*/
