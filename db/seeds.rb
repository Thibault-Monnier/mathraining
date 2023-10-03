# encoding: utf-8

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)


# Sections
Section.delete_all

Section.create!(name:               "Combinatoire",
                abbreviation:       "Combinatoire",
                short_abbreviation: "Comb.",
                initials:           "C",
                description:        "",
                fondation:          false)
Section.create!(name:               "Géométrie",
                abbreviation:       "Géométrie",
                short_abbreviation: "Géom.",
                initials:           "G",
                description:        "",
                fondation:          false)
Section.create!(name:               "Théorie des nombres",
                abbreviation:       "Th. Nombres",
                short_abbreviation: "Th. Nb.",
                initials:           "TN",
                description:        "",
                fondation:          false)
Section.create!(name:               "Algèbre",
                abbreviation:       "Algèbre",
                short_abbreviation: "Alg.",
                initials:           "A",
                description:        "",
                fondation:          false)
Section.create!(name:               "Équations fonctionnelles",
                abbreviation:       "Éq. Fonct.",
                short_abbreviation: "Éq. Fct.",
                initials:           "ÉF",
                description:        "",
                fondation:          false)
Section.create!(name:               "Inégalités",
                abbreviation:       "Inégalités",
                short_abbreviation: "Inég.",
                initials:           "I",
                description:        "",
                fondation:          false)
Section.create!(name:               "Fondements",
                abbreviation:       "Fondements",
                short_abbreviation: "Fond.",
                initials:           "F",
                description:        "",
                fondation:          true)

# Countries
cy = [
["Afghanistan", "af"],
["Afrique du Sud", "za"],
["Albanie", "al"],
["Algérie", "dz"],
["Allemagne", "de"],
["Andorre", "ad"],
["Angola", "ao"],
["Antigua-et-Barbuda", "ag"],
["Arabie saoudite", "sa"],
["Argentine", "ar"],
["Arménie", "am"],
["Australie", "au"],
["Autriche", "at"],
["Azerbaïdjan", "az"],
["Bahamas", "bs"],
["Bahreïn", "bh"],
["Bangladesh", "bd"],
["Barbade", "bb"],
["Belgique", "be"],
["Belize", "bz"],
["Bénin", "bj"],
["Bhoutan", "bt"],
["Biélorussie", "by"],
["Myanmar", "mm"],
["Bolivie", "bo"],
["Bosnie-Herzégovine", "ba"],
["Botswana", "bw"],
["Brésil", "br"],
["Brunei", "bn"],
["Bulgarie", "bg"],
["Burkina Faso", "bf"],
["Burundi", "bi"],
["Cambodge", "kh"],
["Cameroun", "cm"],
["Canada", "ca"],
["Cap-Vert", "cv"],
["Centrafrique", "cf"],
["Chili", "cl"],
["Chine", "cn"],
["Chypre", "cy"],
["Colombie", "co"],
["Comores", "km"],
["République du Congo", "cg"],
["République démocratique du Congo", "cd"],
["Corée du Nord", "kp"],
["Corée du Sud", "kr"],
["Costa Rica", "cr"],
["Côte d'Ivoire", "ci"],
["Croatie", "hr"],
["Cuba", "cu"],
["Danemark", "dk"],
["Djibouti", "dj"],
["Dominique", "dm"],
["Égypte", "eg"],
["Émirats arabes unis", "ae"],
["Équateur", "ec"],
["Érythrée", "er"],
["Espagne", "es"],
["Estonie", "ee"],
["États-Unis", "us"],
["Éthiopie", "et"],
["Fidji", "fj"],
["Finlande", "fi"],
["France", "fr"],
["Gabon", "ga"],
["Gambie", "gm"],
["Géorgie", "ge"],
["Ghana", "gh"],
["Grèce", "gr"],
["Grenade", "gd"],
["Guatemala", "gt"],
["Guinée", "gn"],
["Guinée-Bissau", "gw"],
["Guinée équatoriale", "gq"],
["Guyana", "gy"],
["Haïti", "ht"],
["Honduras", "hn"],
["Hongrie", "hu"],
["Iles Marshall", "mh"],
["Iles Salomon", "sb"],
["Inde", "in"],
["Indonésie", "id"],
["Irak", "iq"],
["Iran", "ir"],
["Irlande", "ie"],
["Islande", "is"],
["Israël", "il"],
["Italie", "it"],
["Jamaïque", "jm"],
["Japon", "jp"],
["Jordanie", "jo"],
["Kazakhstan", "kz"],
["Kenya", "ke"],
["Kirghizistan", "kg"], 
["Kiribati", "ki"],
["Koweït", "kw"],
["Laos", "la"],
["Lesotho", "ls"],
["Lettonie", "lv"],
["Liban", "lb"],
["Liberia", "lr"],
["Libye", "ly"],
["Liechtenstein", "li"],
["Lituanie", "lt"],
["Luxembourg", "lu"],
["Macédoine", "mk"],
["Madagascar", "mg"],
["Malaisie", "my"],
["Malawi", "mw"],
["Maldives", "mv"],
["Mali", "ml"],
["Malte", "mt"],
["Maroc", "ma"],
["Maurice", "mu"],
["Mauritanie", "mr"],
["Mexique", "mx"],
["Micronésie", "fm"],
["Moldavie", "md"],
["Monaco", "mc"],
["Mongolie", "mn"],
["Monténégro", "me"],
["Mozambique", "mz"],
["Namibie", "na"],
["Nauru", "nr"],
["Népal", "np"],
["Nicaragua", "ni"],
["Niger", "ne"],
["Nigéria", "ng"],
["Norvège", "no"],
["Nouvelle-Zélande", "nz"],
["Oman", "om"],
["Ouganda", "ug"],
["Ouzbékistan", "uz"],
["Pakistan", "pk"],
["Palaos", "pw"],
["Palestine", "ps"],
["Panama", "pa"],
["Papouasie-Nouvelle-Guinée", "pg"],
["Paraguay", "py"],
["Pays-Bas", "nl"],
["Pérou", "pe"],
["Philippines", "ph"],
["Pologne", "pl"],
["Portugal", "pt"],
["Qatar", "qa"],
["République dominicaine", "do"],
["République tchèque", "cz"],
["Roumanie", "ro"],
["Royaume-Uni", "uk"],
["Russie", "ru"],
["Rwanda", "rw"],
["Saint-Christophe-et-Niévès", "kn"],
["Sainte-Lucie", "lc"],
["Saint-Marin", "sm"],
["Saint-Vincent-et-les-Grenadines", "vc"],
["Salvador", "sv"],
["Samoa", "ws"],
["Sao Tomé-et-Principe", "st"],
["Sénégal", "sn"],
["Serbie", "rs"],
["Seychelles", "sc"],
["Sierra Leone", "sl"],
["Singapour", "sg"],
["Slovaquie", "sk"],
["Slovénie", "si"],
["Somalie", "so"],
["Soudan", "sd"],
["Soudan du Sud", "ss"],
["Sri Lanka", "lk"],
["Suède", "se"],
["Suisse", "ch"],
["Suriname", "sr"],
["Eswatini", "sz"],
["Syrie", "sy"],
["Tadjikistan", "tj"],
["Tanzanie", "tz"],
["Tchad", "td"],
["Thaïlande", "th"],
["Timor oriental", "tp"],
["Togo", "tg"],
["Tonga", "to"],
["Trinité-et-Tobago", "tt"],
["Tunisie", "tn"],
["Turkménistan", "tm"],
["Turquie", "tr"],
["Tuvalu", "tv"],
["Ukraine", "ua"],
["Uruguay", "uy"],
["Vanuatu", "vu"],
["Vatican", "va"],
["Venezuela", "ve"],
["Viet Nam", "vn"],
["Yémen", "ye"],
["Zambie", "zm"],
["Zimbabwe", "zw"]]

Country.delete_all
cy.each do |c|
  Country.create(name: c[0], code: c[1], name_without_accent: I18n.transliterate(c[0]))
end

# Colors
Color.delete_all
Color.create(pt: 0,    name: "Novice",       color: "#888888", femininename: "Novice")
Color.create(pt: 70,   name: "Débutant",     color: "#08D508", femininename: "Débutante")
Color.create(pt: 200,  name: "Initié",       color: "#008800", femininename: "Initiée")
Color.create(pt: 400,  name: "Compétent",    color: "#00BBEE", femininename: "Compétente")
Color.create(pt: 750,  name: "Qualifié",     color: "#0033FF", femininename: "Qualifiée")
Color.create(pt: 1250, name: "Expérimenté",  color: "#DD77FF", femininename: "Expérimentée")
Color.create(pt: 2000, name: "Chevronné",    color: "#A000A0", femininename: "Chevronnée")
Color.create(pt: 3200, name: "Expert",       color: "#FFA000", femininename: "Experte")
Color.create(pt: 5000, name: "Maître",       color: "#FF4400", femininename: "Maître")
Color.create(pt: 7500, name: "Grand Maître", color: "#CC0000", femininename: "Grand Maître")

# Categories
Category.delete_all
Category.create(name: "Divers")
Category.create(name: "Compétitions")
Category.create(name: "Marathons")
Category.create(name: "Mathraining")
Category.create(name: "Wépion")
