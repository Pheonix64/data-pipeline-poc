
{{
  config(
    materialized='table',
    file_format='iceberg',
    schema='gold'
  )
}}

-- Modèle Gold : Data mart focalisé sur les finances publiques.
-- Prêt à être consommé par un outil de BI pour le Ministère des Finances.
SELECT
    date,
    pib_nominal_milliards_fcfa,
    
    -- Section Recettes
    recettes_fiscales,
    recettes_fiscales_pct_pib,
    
    -- Section Dépenses
    depenses_totales_et_prets_nets,
    
    -- Section Soldes
    solde_budgetaire_global_avec_dons,
    solde_budgetaire_global_hors_dons,
    -- On recalcule le solde en % du PIB pour être sûr
    (solde_budgetaire_global_avec_dons / pib_nominal_milliards_fcfa) * 100 as solde_budgetaire_avec_dons_pct_pib,
    
    -- Section Dette
    encours_de_la_dette,
    encours_de_la_dette_pct_pib

FROM
    {{ ref('dim_uemoa_indicators') }}
WHERE
    -- On peut se concentrer sur une période plus récente pour un dashboard
    EXTRACT(YEAR FROM date) >= 2010
ORDER BY
    date DESC