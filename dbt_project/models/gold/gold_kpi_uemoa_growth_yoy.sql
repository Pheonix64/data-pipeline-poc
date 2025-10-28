{{
  config(
    materialized='table',
    file_format='iceberg',
    schema='gold'
  )
}}

-- Modèle Gold : Calcule la croissance Année-sur-Année (YoY) des KPIs
-- Idéal pour les graphiques de tendance et l'analyse de la performance.
SELECT
    date,
    pib_nominal_milliards_fcfa,
    taux_croissance_reel_pib_pct,
    taux_inflation_moyen_annuel_ipc_pct,
    
    -- Calcul de la croissance YoY du PIB nominal
    LAG(pib_nominal_milliards_fcfa, 1) OVER (ORDER BY date) as pib_nominal_annee_precedente,
    (pib_nominal_milliards_fcfa - LAG(pib_nominal_milliards_fcfa, 1) OVER (ORDER BY date)) 
        / LAG(pib_nominal_milliards_fcfa, 1) OVER (ORDER BY date) * 100 as pib_nominal_croissance_yoy_pct,

    -- Calcul de la croissance YoY des recettes fiscales
    recettes_fiscales,
    (recettes_fiscales - LAG(recettes_fiscales, 1) OVER (ORDER BY date))
        / LAG(recettes_fiscales, 1) OVER (ORDER BY date) * 100 as recettes_fiscales_croissance_yoy_pct,

    -- Calcul de la croissance YoY de la masse monétaire M2
    agregats_monnaie_masse_monetaire_m2,
    (agregats_monnaie_masse_monetaire_m2 - LAG(agregats_monnaie_masse_monetaire_m2, 1) OVER (ORDER BY date))
        / LAG(agregats_monnaie_masse_monetaire_m2, 1) OVER (ORDER BY date) * 100 as m2_croissance_yoy_pct

FROM
    {{ ref('dim_uemoa_indicators') }}
ORDER BY
    date DESC