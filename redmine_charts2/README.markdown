Redmine Charts
==============

Plugin which integrates with Redmine following charts: burndown, timeline, ratios of logged hours and issues, deviations of logged hours. 

## Instalation

Download the sources and put them to your vendor/plugins folder.

For Redmine 2.0.x

    $ cd {REDMINE_ROOT}
    $ git clone git://github.com/pharmazone/redmine_charts2 plugins/redmine_charts2

For Redmine 2.1.x

    $ cd {REDMINE_ROOT}
    $ git clone git://github.com/pharmazone/redmine_charts2 plugins/redmine_charts2
    $ cd plugins/redmine_charts2
    $ git checkout redmine21

Install OpenFlashChart plugin. 

    $ cd {REDMINE_ROOT}
    $ git clone git://github.com/pullmonkey/open_flash_chart.git plugins/open_flash_chart

Copy OpenFlashChart's assests.

    $ cd {REDMINE_ROOT}
    $ cp -r plugins/open_flash_chart/assets public/plugin_assets/open_flash_chart

Migrate database.

    $ rake redmine:plugins RAILS_ENV=production

Run Redmine and have a fun!

## Translations

- ja by In Dow
- pt-br by Enderson Maia
- nl by onno-schuit
- en by Maciej Szczytowski and Rocco Stanzione
- ru by Vadim Kruchkov and [AlexStein](https://github.com/AlexStein)
- es by Rafael Lorenzo, José Javier Sianes Ruiz 
- pl by Maciej Szczytowski
- fr by Yannick Quenec'hdu
- ko by Ki Won Kim
- da by Jakob Skjerning
- de by Bernd Engelsing
- sv by Martin Bagge

Thanks for the contribution. 

## Changelog

### 2.1 
- compatible with Redmine 2.1 

### 2.0
- compatible with Redmine 2.0.3



### 0.1.1
- compatible with Redmine 1.1.2
- Only list active projects, fix from Anton Kravchenko's fork. 
- weeks starts from 0 - yondo
- support version has no tickets case Anton Kravchenko (author)
- avoid error  kzgs (author)
- use Version#start_date for start date of burndown chart  kzgs (author)
- fixing bug where the index is not found in range[:keys] from: Michael Co... 

### 0.1.0

- migration to Redmine 0.9.x
- new conditions (owners, authors, statuses and projects)
- conditions in burndown chart
- multiselection in conditions (#3)
- new issue chart (#2)
- issues with closed status are considered as 100% complete (#1)
- new translations (ko, da, de)
- new chart - burndown with velocity (#12)
- support for subissues (#36)
- saved condition (#24)

### 0.0.14

- new translations (fr)

### 0.0.13

- bug fixes (#13, #15)
- saving charts as images (#14)

### 0.0.12

- many bug fixes (#6, #7, #8, #9, #10)
- new conditions (trackers, priorities, versions)
- pages on deviations chart (#5)
- hours logged for project and not estimated issues on deviations chart

## Screenshots

![](http://farm4.static.flickr.com/3568/4599631980_fe37fc3fd7_o.jpg)

![](http://farm5.static.flickr.com/4035/4599631940_3b4d1a2642_o.jpg)

![](http://farm2.static.flickr.com/1298/4599014565_1d9be4c04d_o.jpg)

![](http://farm2.static.flickr.com/1159/4599014491_c22cba7925_o.jpg)

![](http://farm2.static.flickr.com/1056/4599014527_d8b7b6457f_o.jpg)

![](http://farm2.static.flickr.com/1401/4599631776_65e0d0bfa2_o.jpg)

