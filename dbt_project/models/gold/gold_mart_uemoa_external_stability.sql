
{{
  config(
    materialized='table',
    file_format='iceberg',
    schema='gold'
  )
}}

-- Modèle Gold : Indicateurs de soutenabilité externe.
-- Calcule les indicateurs clés de la stabilité externe de l'UEMOA.

SELECT
    date,
    
    -- Balance commerciale et compte courant
    exportations_biens_fob,
    importations_biens_fob,
    balance_des_biens,
    compte_transactions_courantes,
    balance_courante_sur_pib_pct,
    
    -- Importations mensuelles moyennes
    (importations_biens_fob / 12) as importations_mensuelles_moyennes,
    
    -- Taux de couverture des importations par les exportations
    CASE 
        WHEN importations_biens_fob != 0 
        THEN (exportations_biens_fob / importations_biens_fob) * 100
        ELSE NULL
    END as taux_couverture_importations_pct,
    
    -- Degré d'ouverture commerciale
    -- (Exportations + Importations) / PIB * 100
    CASE 
        WHEN pib_nominal_milliards_fcfa != 0 
        THEN ((exportations_biens_fob + importations_biens_fob) / pib_nominal_milliards_fcfa) * 100
        ELSE NULL
    END as degre_ouverture_commerciale_pct,

    -- Taux de couverture de l'émission monétaire (indicateur de réserves)
    taux_couverture_emission_monetaire,
    
    -- Indicateur de soutenabilité de la dette externe
    encours_de_la_dette,
    encours_de_la_dette_pct_pib

FROM
    {{ ref('dim_uemoa_indicators') }}
WHERE
    importations_biens_fob IS NOT NULL AND importations_biens_fob != 0
ORDER BY
    date DESC
