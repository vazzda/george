# george

use example: ./george.sh -s 2016-11-01 -u 2016-12-01

## arguments
* p - pause mode, for assessing commits
* a - git pull --rebase for every project
* s - since date, mirrors git --since arg. By default is yesterday
* u -  since date, mirrors git --since arg. By default is today


## exmaples
use exmaples:

for full assesment
./george.sh -p -a -s 2019-11-01 -u 2022-12-01

vieving:
./george.sh -s 2016-11-01 -u 2016-12-01

where results would by like:
* ruslan--47@yandex.ru, undecided: 13293, trusted: 16823, untrusted: 18745, notUniq: 198, sum: 49059, ./together
* oleg.fox.code@gmail.com, 1058, (sanitazed from 3424), oleg.fox.code@gmail.com, ./pablo-baikal
* nikit.kutselaj2013@yandex.ru, 46, (sanitazed from 46), nikit.kutselaj2013@yandex.ru, ./active-age-admin

where
* ruslan--47@yandex.ru -- develper name with different emails
* undecided: 13293 -- undecided commits counter
* trusted: 16823 -- trusted commits counter
* untrusted: 18745 -- untrusted commits counter (decision not to trust)
* notUniq: 198 -- commits that are not uniq, like cherry-picks, etc
* sum: 49059 -- summory


## install
* clone george to empty folder
* put repos on the same level
* run george from its folder
* its a really hardcoded project, so u shoulndt mess with folder structures or names

## confing
* the only thing u can config is user list, at the users.json
