/*
DECLARE @FechaInicio DATE = '2025-01-01';
DECLARE @FechaFin DATE = '2025-08-31';*/

declare @fecha date= eomonth('2026-08-30');
 
SELECT
   --car.FechaCorte AS FechaCorte,
   car.CarteraKey                              AS CarteraKey
-- 1. Perfil del cliente
    --car.ClienteKey                              AS ClienteKey
   ,cli.Edad                                    AS EdadCliente
   ,cli.Genero                                  AS GeneroCliente
   ,cli.EstadoCivil                             AS EstadoCivilCliente
   ,cli.NumeroHijos                             AS NumeroHijosCliente
   ,cli.Ciudad                                  AS CiudadCliente
   ,cli.Departamento                            AS DepartamentoCliente
   ,cli.Barrio                                  AS BarrioCliente
   ,cli.edadComoClienteMeses                    AS AntiguedadClienteMeses
   ,cli.Segmento                                AS SegmentoCliente
   ,cli.Nacionalidad                            AS NacionalidadCliente
   ,cli.JefaHogar                               AS EsJefaHogar

-- 2. Situación económica
   -- ,cli.MontoIngreso                            AS IngresoClienteBs
   ,cli.NivelIngreso                            AS NivelIngresoCliente
   ,cli.NivelEgreso                             AS NivelEgresoCliente
   ,cli.TipoFuenteIngreso                       AS FuenteIngresoCliente
   ,cli.Profesion                               AS ProfesionCliente
   ,cli.GradoInstruccion                        AS GradoInstruccionCliente
   ,car.Patrimonio                              AS PatrimonioClienteBs
   ,car.Activos                                 AS ActivosClienteBs
   ,car.VentasAnuales                           AS VentasAnualesClienteBs

-- 3. Endeudamiento externo (Infocred)
   ,inf.PeorCalificacionASFIKey                 AS InfocredPeorCalificacionASFIKey
   ,inf.SaldoVigenteBs                          AS InfocredSaldoVigenteBs
   ,inf.SaldoVencidoBs                          AS InfocredSaldoVencidoBs
   ,inf.SaldoEjecucionBs                        AS InfocredSaldoEjecucionBs
   ,inf.SaldoCantigadoBs                        AS InfocredSaldoCastigadoBs
   ,inf.SaldoContingenteBs                      AS InfocredSaldoContingenteBs
   --,inf.MaximaFechaVencimiento                  AS InfocredMaxFechaVencimiento
   ,DATEDIFF(month,car.FechaCorte,inf.MaximaFechaVencimiento) AS InfocredMesesHastaMaxVencimiento
   ,inf.MontoDeudaTotalBs                       AS InfocredMontoDeudaTotalBs
   ,inf.CuotaBs                                 AS InfocredCuotaBs
   ,inf.CantidadDeudasOtrasEntidades            AS InfocredCantDeudasOtrasEntidades
   ,inf.CantidadDeudasDeudor                    AS InfocredCantDeudasDeudor
   ,inf.CantidadDeudasCodeudor                  AS InfocredCantDeudasCodeudor
   ,inf.EsCreditoVivienda                       AS InfocredEsCreditoVivienda

-- 4. Productos y canales
   ,car.Productocartera                         AS ProductoCartera
   ,cli.EsDeudorcartera                         AS EsDeudorCartera
   ,cli.EsCodeudorcartera                       AS EsCodeudorCartera
   ,cli.EsGarantecartera                        AS EsGaranteCartera
   ,cli.EsClienteActivoDigital                  AS EsClienteDigital
   ,cli.EsclienteTinka                          AS EsClienteTinka

-- 5. Características del crédito
   ,car.CodigoOficialCredito                    AS CodigoOficialCredito
   ,car.NombreOficialCredito                    AS NombreOficialCredito
   ,car.TipoCredito                             AS TipoCredito
   ,car.TipoBanca                               AS TipoBanca
   ,car.TasaEfectiva                            AS TasaEfectivaCredito
   ,car.TasaBase                                AS TasaBaseCredito
   ,car.TasaTRE                                 AS TasaTRECredito
   ,car.PlazoDias                               AS PlazoCreditoDias
   ,car.PlazoMeses                              AS PlazoCreditoMeses
   ,car.FrecuenciaPago                          AS FrecuenciaPagoCredito
   ,car.TipoAmortizacion                        AS TipoAmortizacion
   ,car.CantidadReprogramaciones                AS CantidadReprogramaciones
   ,car.MontoReprogramadoBs                     AS MontoReprogramadoBs
   ,car.EstadoCredito                           AS EstadoCredito
   ,car.LineaCredito                            AS LineaCredito
   ,car.MontoLineaCreditoBs                     AS MontoLineaCreditoBs

-- 6. Actividad económica
   ,car.SectorEconomicoCliente                  AS SectorEconomicoCliente
   ,car.SectorEconomicoCredito                  AS SectorEconomicoCredito
   ,car.ActividadEconomicaCliente               AS ActividadEconomicaCliente
   ,car.ActividadEconomicaCredito               AS ActividadEconomicaCredito
   ,car.ActividadEconomicaClienteCAEDEC         AS ActividadEconomicaClienteCAEDEC
   ,car.ActividadEconomicaCreditoCAEDEC         AS ActividadEconomicaCreditoCAEDEC
   ,car.Nrotrabajadores                         AS NumeroTrabajadores
   ,car.IndiceActividad                         AS IndiceActividadEconomica
   ,car.TamanioEmpresa                          AS TamanioEmpresa

-- 7. Endeudamiento y garantías
   ,car.SaldoBs                                 AS SaldoCreditoBs
   ,car.SaldoCapitalBs                          AS SaldoCapitalBs
   ,car.SaldoDiferidoBs                         AS SaldoDiferidoBs
   ,car.InteresBs                               AS InteresBs
   ,car.OtrosRubrosBs                           AS OtrosRubrosBs
   ,car.MontoDesembolsadoBs                     AS MontoDesembolsadoBs
   ,car.GarantiaHipotecaria                     AS GarantiaHipotecariaBs
   ,car.GarantiaPersonal                        AS GarantiaPersonalBs
   ,car.GarantiaPrendaria                       AS GarantiaPrendariaBs
   ,car.GarantiaCaptacion                       AS GarantiaCaptacionBs
   ,car.GarantiaOtros                           AS GarantiaOtrosBs
   ,car.GarantiaDocumentosCustodia              AS GarantiaDocumentosCustodiaBs
   ,car.MontoGarantiaBs                         AS MontoGarantiaTotalBs
   ,car.PrevisionRequeridaBs                    AS PrevisionRequeridaBs
   ,car.PrevisionCiclicaBs                      AS PrevisionCiclicaBs

-- 8. Fechas del crédito
   
   --,car.FechaCorte                              AS FechaCorte
   ,DATEDIFF(month,car.FechaCorte,car.FechaVencimiento) AS MesesHastaVencimientoCredito
   ,car.FechaVencimiento                        AS FechaVencimiento
   ,DATEDIFF(month,car.FechaCorte,car.FechaVencimientoReprogramada) AS MesesHastaVencimientoReprogramado
   ,car.FechaVencimientoReprogramada            AS FechaVencimientoReprogramada
   ,DATEDIFF(month,car.FechaCorte,car.FechaRefinanciamiento) AS MesesDiferenciaRefinanciamiento
   ,car.FechaRefinanciamiento                   AS FechaRefinanciamiento
   ,DATEDIFF(day,car.FechaCorte,car.FechaProximoPago) AS DiasHastaProximoPago
   ,car.FechaProximoPago                        AS FechaProximoPago

-- 9. Eventos
   ,eve.Evento                                  AS Evento
   --no se usara se tiene el intervalo en duraciondias
   
   --,eve.FechaInicio                             AS EventoFechaInicio
   --,eve.FechaFin                                AS EventoFechaFin
   ,eve.DuracionDias                            AS EventoDuracionDias
   ,eve.CodigoRegional                          AS EventoCodigoRegional
   ,eve.CodigoDepartamento                      AS EventoCodigoDepartamento
   --,eve.Departamento                            AS EventoDepartamento
   ,eve.Descripcion                             AS EventoDescripcion

-- 10. Comportamiento de pago
   ,car.MaxDiasMoraMes                          AS MaxDiasMoraMes /**/
   ,car.MaxDiasMora3M                           AS MaxDiasMora3M
   ,car.PromedioMora3M                          AS PromedioMora3M
   ,car.MesesConMora3M                          AS MesesConMora3M
   ,car.MaxDiasMora6M                           AS MaxDiasMora6M
   ,car.PromedioMora6M                          AS PromedioMora6M
   ,car.MesesConMora6M                          AS MesesConMora6M
   ,car.MaxDiasMora12M                          AS MaxDiasMora12M
   ,car.PromedioMora12M                         AS PromedioMora12M
   ,car.MesesConMora12M                         AS MesesConMora12M
   ,car.TasaCumplimiento                        AS TasaCumplimiento
   ,car.AntiguedadCreditoMeses                  AS AntiguedadCreditoMeses
   ,car.CalificacionFIE                         AS CalificacionFIE
   ,car.CalificacionASFI                        AS CalificacionASFI

-- 11. Comportamiento transaccional
   ,tra.CantidadTrx                             AS CantidadTrx
   ,tra.MontoTotalBs                            AS MontoTotalTrxBs
   ,tra.CantidadDepositos                       AS CantidadDepositos
   ,tra.CantidadRetiros                         AS CantidadRetiros
   ,tra.MontoDepositosBs                        AS MontoDepositosBs
   ,tra.MontoRetirosBs                          AS MontoRetirosBs
   ,tra.FlujoNetoBs                             AS FlujoNetoBs
   ,tra.CantidadQR                              AS CantidadQR
   ,tra.CantidadDigital                         AS CantidadDigital
   ,tra.CantidadPresencial                      AS CantidadPresencial
   ,tra.CantidadAutoservicio                    AS CantidadAutoservicio
   ,tra.CantidadProcesamiento                   AS CantidadProcesamiento
   ,tra.MontoQR                                 AS MontoQRBs
   ,tra.MontoDigital                            AS MontoDigitalBs
   ,tra.MontoPresencial                         AS MontoPresencialBs
   ,tra.MontoAutoservicio                       AS MontoAutoservicioBs
   ,tra.MontoProcesamiento                      AS MontoProcesamientoBs

-- 12. Histórico transaccional 3M
   ,trh.CantidadTrx_3M                          AS CantidadTrx3M
   ,trh.MontoTotalBs_3M                         AS MontoTotalBs3M
   ,trh.CantidadDepositos_3M                    AS CantidadDepositos3M
   ,trh.CantidadRetiros_3M                      AS CantidadRetiros3M
   ,trh.MontoDepositosBs_3M                     AS MontoDepositosBs3M
   ,trh.MontoRetirosBs_3M                       AS MontoRetirosBs3M

-- 13. Histórico transaccional 6M
   ,trh.CantidadTrx_6M                          AS CantidadTrx6M
   ,trh.MontoTotalBs_6M                         AS MontoTotalBs6M
   ,trh.CantidadDepositos_6M                    AS CantidadDepositos6M
   ,trh.CantidadRetiros_6M                      AS CantidadRetiros6M
   ,trh.MontoDepositosBs_6M                     AS MontoDepositosBs6M
   ,trh.MontoRetirosBs_6M                       AS MontoRetirosBs6M

-- 14. Histórico transaccional 12M
   ,trh.CantidadTrx_12M                         AS CantidadTrx12M
   ,trh.MontoTotalBs_12M                        AS MontoTotalBs12M
   ,trh.CantidadDepositos_12M                   AS CantidadDepositos12M
   ,trh.CantidadRetiros_12M                     AS CantidadRetiros12M
   ,trh.MontoDepositosBs_12M                    AS MontoDepositosBs12M
   ,trh.MontoRetirosBs_12M                      AS MontoRetirosBs12M
   ,trh.MesesConHistoria                        AS MesesConHistoria

FROM Resultados.dcar.dominiocartera car 
   LEFT JOIN (
               select clientekey,fechacorte,Edad
                     ,Genero
                     ,EstadoCivil
                     ,NumeroHijos
                     ,Ciudad
                     ,Departamento
                     ,Barrio
                     ,edadComoClienteMeses
                     ,Segmento
                     ,Nacionalidad
                     ,JefaHogar
                     ,NivelIngreso
                     ,NivelEgreso
                     ,TipoFuenteIngreso
                     ,Profesion
                     ,GradoInstruccion
                     ,EsDeudorcartera
                     ,EsCodeudorcartera
                     ,EsGarantecartera
                     ,EsClienteActivoDigital
                     ,EsclienteTinka
                     ,tipopersona
                     ,row_number() over(partition by clientekey , fechacorte order by asignacion_motivo )as rn 
                  from resultados.dcli.dominioclientes 
                  where FechaCorte = @fecha) AS cli
         --LEFT JOIN outer AS cli
                                                                        ON car.ClienteKey = cli.ClienteKey AND car.FechaCorte = cli.FechaCorte and cli.rn =1 --and cli.ASIGNACION_Motivo = 'cartera'
   LEFT JOIN Inteligencia_Comercial.dbo.TransaccionesMensuales tra      ON car.ClienteKey = tra.ClienteKey  and car.fechaCorte = tra.fecha
	LEFT JOIN test.dbo.fn_DominioMensual(@fecha) trh					      ON car.clientekey= trh.ClienteKey --es una funcion
	LEFT JOIN INTELIGENCIA_COMERCIAL.dbo.clienteinfocred  inf            ON car.ClienteKey=inf.clientekey   and car.FechaCorte = CONVERT(date,convert(varchar(8),inf.fechakey,112))
	LEFT JOIN Inteligencia_Comercial.dbo.EventosRelevantes eve           ON car.CodigoRegional = eve.CodigoRegional 
                                                                           and car.fechacorte between CONVERT(date,eve.FechaInicio,103) and CONVERT(date,eve.FechaFin,103)

where car.FechaCorte = EOMONTH(@fecha)
	--and car.NumeroCuotaActual IS NULL --OR NumeroCuotas IS NULL
   and car.FechaCorte = EOMONTH(car.FechaCorte)
	and car.Producto='CARTERA'
	and car.TipoBanca = 'BANCA MICROEMPRESA'
	and car.EstadoCredito = 'VIGENTE' 
	and car.FrecuenciaPago = 'MENSUAL'
   and cli.TipoPersona = 'PERSONA NATURAL'