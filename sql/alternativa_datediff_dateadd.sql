/*
   1) ALTERNATIVA SET-BASED: DATEDIFF + DATEADD
   

   Idea:
   - DATEDIFF calcula cuántos cambios de mes separan conversión y cancelación.
   - DATEADD proyecta SIEMPRE desde conversion_date.
   - Así evitamos encadenar fechas ajustadas y perder el día ancla.

   Ejemplo:
   31/01 + 1 mes = 28/02
   31/01 + 2 meses = 31/03
   NO hacemos: 28/02 + 1 mes = 28/03
*/

CREATE OR ALTER VIEW staging.vw_validation_result_dateadd AS

WITH base AS (
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

        DATEDIFF(
            MONTH,
            conversion_date,
            cancellation_request_date
        ) AS month_offset

    FROM staging.fact_subscriptions_demo

    WHERE plan_type = 'pro'
      AND start_date IS NOT NULL
      AND conversion_date IS NOT NULL
      AND cancellation_request_date IS NOT NULL
      AND trial_churn_date IS NULL
      AND paid_churn_date IS NOT NULL
),

candidate AS (
    SELECT
        b.*,

        DATEADD(
            MONTH,
            b.month_offset,
            b.conversion_date
        ) AS candidate_paid_churn_date

    FROM base AS b
),

expected AS (
    SELECT
        c.*,

        CASE
            WHEN c.cancellation_request_date < c.candidate_paid_churn_date
                THEN c.candidate_paid_churn_date

            ELSE DATEADD(
                    MONTH,
                    c.month_offset + 1,
                    c.conversion_date
                 )
        END AS expected_paid_churn_date

    FROM candidate AS c
)

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
        WHEN paid_churn_date <> expected_paid_churn_date
            THEN N'error'

        WHEN DAY(expected_paid_churn_date) <> anchor_day
            THEN N'excepción válida'

        ELSE N'correcto'
    END AS validation_result

FROM expected;
GO


/* Comprobación */
SELECT *
FROM staging.vw_validation_result_dateadd
WHERE validation_result = N'error';
GO