# ekylibre-hve

Plugin Ekylibre pour le calcul de l'audit HVE3 (Haute Valeur Environnementale, référentiel V4.4 applicable depuis le 01/01/2025).

## Périmètre actuel — PR1

- Squelette engine + navigation + i18n
- Modèles `HveAudit`, `HveAuditItem`, `HveCmrProduct`, `HveNitrogenExportCoefficient`, `HveScoringTable`
- Données de référence vendorisées (extrait CMR 2025, coefficients d'export azote Comifer, tables de scoring IFT)
- Rake `hve:reference:load` pour (re)charger les référentiels dans le tenant courant
- Vue index + new + show **squelette** (pas encore de calcul de score)

Le scoring effectif des 35 critères sera ajouté dans les PRs suivantes (PR2 biodiversité, PR3 phyto, PR4 fertilisation, PR5 irrigation, PR6 verdict + export Excel Certibase).

## Installation (dev local)

Ajouter dans `Gemfile.local` du repo principal Ekylibre :

```ruby
gem 'ekylibre_hve', path: '/ekylibre-plugins/ekylibre-hve'
```

Puis dans le conteneur app :

```bash
bundle install
rake tenant:migrate TENANT=<nom_tenant>
TENANT=<nom_tenant> rake hve:reference:load
```

## Conventions

- Toutes les classes sont sous le namespace `Hve::` (modèles) ou `EkylibreHve::` (libs/engine).
- Tables nommées `hve_*` pour isolation claire des modèles core.
- Référentiels chargés par tenant, pas dans le schéma `lexicon` partagé (mise à jour annuelle requise par HVE).
- Pas de modification au schéma core en PR1.

## Licence

AGPL-3.0-only, comme le reste d'Ekylibre.
