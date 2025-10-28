
{{
  config(
    materialized='table',
    file_format='iceberg',
    schema='gold'
  )
}}

-- Modèle Gold : Prêt pour un tableau de bord de pilotage monétaire.
-- Calcule la croissance des agrégats et les ratios clés.

SELECT
    date,
    pib_nominal_milliards_fcfa,
    agregats_monnaie_masse_monetaire_m2,
    taux_inflation_moyen_annuel_ipc_pct,
    
    -- Croissance Année-sur-Année (YoY) de la masse monétaire
    (agregats_monnaie_masse_monetaire_m2 - LAG(agregats_monnaie_masse_monetaire_m2, 1) OVER (ORDER BY date))
        / LAG(agregats_monnaie_masse_monetaire_m2, 1) OVER (ORDER BY date) * 100 as m2_croissance_yoy_pct,

    -- Vélocité de la monnaie (V) : vitesse à laquelle l'argent circule
    -- V = PIB Nominal / M2
    pib_nominal_milliards_fcfa / agregats_monnaie_masse_monetaire_m2 as velocite_monnaie,

    -- Taux de couverture de l'émission (déjà présent, mais vital)
    taux_couverture_emission_monetaire

FROM
    {{ ref('dim_uemoa_indicators') }}
-- NOTE: Assurez-vous que votre modèle Silver 'dim_uemoa_indicators'
-- inclut bien 'agregats_monnaie_masse_monetaire_m2' et 'taux_couverture_emission_monetaire'
WHERE
    agregats_monnaie_masse_monetaire_m2 IS NOT NULL
ORDER BY
    date DESC