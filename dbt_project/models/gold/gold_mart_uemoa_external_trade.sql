{{
  config(
    materialized='table',
    file_format='iceberg',
    schema='gold'
  )
}}

-- Modèle Gold : Data mart focalisé sur le commerce extérieur et la balance des paiements.
-- Prêt à être consommé par un outil de BI pour la BCEAO ou le Commerce.
SELECT
    date,
    pib_nominal_milliards_fcfa,
    
    -- Balance commerciale
    exportations_biens_fob,
    importations_biens_fob,
    balance_des_biens,
    (balance_des_biens / pib_nominal_milliards_fcfa) * 100 as balance_des_biens_pct_pib,

    -- Balance courante
    compte_transactions_courantes,
    balance_courante_sur_pib_pct

FROM
    {{ ref('dim_uemoa_indicators') }}
ORDER BY
    date DESC