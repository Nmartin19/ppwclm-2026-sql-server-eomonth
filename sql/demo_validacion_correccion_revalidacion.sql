


--						DEMO I: VALIDACIÓN TEMPORAL CON EOMONTH


-- 1. ORIGEN: construir la consulta base.
-- Seleccionamos los episodios objetivo y obtenemos el día ancla desde conversion_date 
-- calculamos los límites del calendario para la fecha de cancelacion y del mes siguiente. 

 CREATE OR ALTER VIEW staging.vw_validation_result AS
 WITH consulta_base AS (

      SELECT
           subscription_id,
           customer_id,
           plan_type,
           registration_date,
           start_date,
           trial_start_date,
           conversion_date,
           trial_churn_date,
           cancellation_request_date,
           paid_churn_date,
           DAY(conversion_date) AS anchor_day,
           EOMONTH(cancellation_request_date) AS cancellation_month_end,
           EOMONTH(cancellation_request_date, 1) AS next_month_end

      FROM staging.fact_subscriptions_demo
      WHERE plan_type = 'pro'
            AND start_date IS NOT NULL
            AND conversion_date IS NOT NULL
            AND cancellation_request_date IS NOT NULL
            AND trial_churn_date IS NULL
            AND paid_churn_date IS NOT NULL),


--    2. FECHA CANDIDATA
--       Construir el corte correspondiente al mes en el que se solicita la cancelación.
--       Si el día ancla existe, se conserva. Si no existe, se utiliza el último día del mes.

    Candidate_churn_date AS (
    
         SELECT
              cb.*,
              CASE
                  WHEN cb.anchor_day <= DAY(cb.cancellation_month_end)
                  THEN
                      DATEFROMPARTS(
                                    YEAR(cb.cancellation_month_end),
                                    MONTH(cb.cancellation_month_end),
                                    cb.anchor_day)
                  ELSE 
                      cb.cancellation_month_end
                  END AS candidate_paid_churn_date

         FROM consulta_base cb),


-- 3. FECHA ESPERADA
    -- Si la cancelación se solicita antes del corte, la candidata es la fecha esperada.
    -- Si se solicita en el corte o después, se calcula el corte del mes siguiente


   Expected_churn_date AS (

          SELECT
                cd.*,
                CASE
                    WHEN cd.cancellation_request_date < cd.candidate_paid_churn_date
                    THEN cd.candidate_paid_churn_date
                    WHEN cd.anchor_day <= DAY(cd.next_month_end)
                    THEN
                        DATEFROMPARTS(
                                     YEAR(cd.next_month_end),
                                     MONTH(cd.next_month_end),
                                     cd.anchor_day
                                     )

                    ELSE 
                        cd.next_month_end
                    END AS expected_paid_churn_date

          FROM Candidate_churn_date cd)


-- 4. VALIDACIÓN: comparar la fecha registrada con la fecha esperada.


   SELECT 

           subscription_id,
           customer_id,
           plan_type,
           registration_date,
           start_date,
           trial_start_date,
           conversion_date,
           trial_churn_date,
           cancellation_request_date,
           paid_churn_date,
           candidate_paid_churn_date,
           expected_paid_churn_date,
           CASE
               WHEN paid_churn_date <> expected_paid_churn_date THEN 'error'
               WHEN DAY(expected_paid_churn_date) <> anchor_day THEN 'excepción válida'
               ELSE 'correcto'
               END as validation_result

    FROM expected_churn_date;

    GO



-- 5.- Filtramos casos erroneos a partir de vista de validación

   SELECT *
   FROM staging.vw_validation_result
   WHERE validation_result = 'error'








   --                                    DEMO II: CORRECCIÓN Y REVALIDACIÓN

   -- 1. Comprobar el Nº de errores antes de la corrección. N = 400


   SELECT COUNT(*) AS errores_antes_update
   FROM staging.vw_validation_result
   WHERE validation_result = 'error'

   -- 2 Comenzar una transaccion sin confirmar los cambios. 

   BEGIN TRANSACTION 


   -- 3 Aplicamos el UPDATE solo a las 400 filas con errores. 
   -- Para esta consulta la vista aporta la fecha esperada y la tabla original recibirá la correción.

   UPDATE subscriptions
   SET subscriptions.paid_churn_date = validation.expected_paid_churn_date 

   FROM staging.fact_subscriptions_demo AS subscriptions 
   
   JOIN staging.vw_validation_result AS validation
        ON subscriptions.subscription_id = validation.subscription_id

    WHERE validation.validation_result = 'error'
          AND subscriptions.paid_churn_date <> validation.expected_paid_churn_date


DECLARE @updated_rows INT = @@ROWCOUNT;
DECLARE @remaining_errors INT;


-- Revalidar antes de decidir

SELECT @remaining_errors = COUNT(*)

FROM staging.vw_validation_result

WHERE validation_result = 'error';


-- Decisión final

IF @remaining_errors = 0

BEGIN

    COMMIT TRANSACTION;

    SELECT
        @updated_rows AS updated_rows,
        @remaining_errors AS remaining_errors,
        'COMMIT' AS transaction_result;

END

ELSE

BEGIN

    ROLLBACK TRANSACTION;

    SELECT
        @updated_rows AS attempted_rows,
        @remaining_errors AS remaining_errors,
        'ROLLBACK' AS transaction_result;

END;
   


   

   
