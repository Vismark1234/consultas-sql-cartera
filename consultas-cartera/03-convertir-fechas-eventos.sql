/* CONVERTIR FECHAS DE EVENTOS A DATE (EJECUTAR UNA SOLA VEZ) */

SET NOCOUNT ON;
SET XACT_ABORT ON;
SET DATEFORMAT DMY;

/*
    Antes de modificar la tabla, se detiene el proceso si existe una fecha
    vacia o que no tenga el formato dia/mes/anio.
*/

IF EXISTS
(
    SELECT 1
    FROM Inteligencia_Comercial.dbo.EventosRelevantes
    WHERE
           (
               FechaInicio IS NOT NULL
               AND
               (
                   LTRIM(RTRIM(FechaInicio)) = ''
                   OR TRY_CONVERT(DATE, FechaInicio, 103) IS NULL
               )
           )
        OR (
               FechaFin IS NOT NULL
               AND
               (
                   LTRIM(RTRIM(FechaFin)) = ''
                   OR TRY_CONVERT(DATE, FechaFin, 103) IS NULL
               )
           )
)
BEGIN
    THROW 50001, 'Existen fechas vacias o invalidas. Corrija esos registros antes de continuar.', 1;
END;

/* Modificacion directa de las dos columnas en la tabla original. */

BEGIN TRY
    BEGIN TRANSACTION;

    ALTER TABLE Inteligencia_Comercial.dbo.EventosRelevantes
        ALTER COLUMN FechaInicio DATE NULL;

    ALTER TABLE Inteligencia_Comercial.dbo.EventosRelevantes
        ALTER COLUMN FechaFin DATE NULL;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    THROW;
END CATCH;

/* Comprobacion final del tipo de dato. */

SELECT
    c.name AS Columna,
    t.name AS TipoDato,
    c.is_nullable AS PermiteNulos
FROM sys.columns c
INNER JOIN sys.types t
        ON t.user_type_id = c.user_type_id
WHERE c.object_id = OBJECT_ID('Inteligencia_Comercial.dbo.EventosRelevantes')
  AND c.name IN ('FechaInicio', 'FechaFin');
