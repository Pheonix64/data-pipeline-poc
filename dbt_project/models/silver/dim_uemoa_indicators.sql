{{
  config(
    materialized='table',
    file_format='iceberg',
    schema='silver'
  )
}}

-- Ce modèle sert de "source de vérité" propre pour tous les modèles Gold.
-- Il sélectionne depuis la source et applique les premières transformations/nettoyages.
SELECT
    date,
    pib_nominal_milliards_fcfa,
    poids_secteur_primaire_pct,
    poids_secteur_secondaire_pct,
    poids_secteur_tertiaire_pct,
    taux_croissance_reel_pib_pct,
    taux_inflation_moyen_annuel_ipc_pct,
    recettes_fiscales,
    recettes_fiscales_pct_pib,
    depenses_totales_et_prets_nets,
    solde_budgetaire_global_avec_dons,
    solde_budgetaire_global_hors_dons,
    encours_de_la_dette,
    encours_de_la_dette_pct_pib,
    exportations_biens_fob,
    importations_biens_fob,
    balance_des_biens,
    compte_transactions_courantes,
    balance_courante_sur_pib_pct,
    agregats_monnaie_masse_monetaire_m2,
    taux_couverture_emission_monetaire
    -- Ajoutez toutes les autres colonnes dont vous avez besoin
FROM
    {{ source('bronze', 'indicateurs_economiques_uemoa') }}
WHERE
    pib_nominal_milliards_fcfa IS NOT NULL