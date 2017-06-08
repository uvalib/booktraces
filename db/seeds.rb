# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
BookStatus.create([
   { name: 'valid' }, { name: 'barcode mismatch' }, { name: 'not on shelf' },
   { name: 'no barcode' }, { name: 'cataloging problem'}, { name: 'too late'},
   { name: 'wrong date'}, { name: 'multiple records'}, { name: 'duplicate'}
])

InterventionType.create([
   { category: "inscription", name: 'owner or indeterminate' },
   { category: "inscription", name: 'gift' },
   { category: "inscription", name: 'author' },
   { category: "inscription", name: 'covered by bookplate' },
   { category: "annotation", name: 'verbal' },
   { category: "annotation", name: 'non-verbal' },
   { category: "annotation", name: 'juvenile' },
   { category: "marginalia", name: 'verbal' },
   { category: "marginalia", name: 'non-verbal' },
   { category: "marginalia", name: 'underscoring' },
   { category: "insertion", name: 'loose non-botanical' },
   { category: "insertion", name: 'tipped' },
   { category: "insertion", name: 'fully pasted' },
   { category: "insertion", name: 'botanical' },
   { category: "insertion", name: 'extra-illustration' },
   { category: "artwork", name: 'artwork' },
   { category: "artwork", name: 'juvenile' },
   { category: "library", name: 'label or bookplate' },
   { category: "library", name: 'stamp or embossing' }
])
