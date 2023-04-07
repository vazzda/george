#!/bin/bash


#check if date or gdate is installed and use it
if [ -x "$(command -v date)" ]; then
    echo "date is presented"
    date_exec="date"
elif [ -x "$(command -v gdate)" ]; then
    echo "gdate is presented"
    date_exec="gdate"
else
    echo "gdate (mac) or date (linux) should be presented for this script to work"
    exit 1
fi


opt_showUsersFront='false'
opt_showUsersPhp='false'
opt_showUsersJava='false'
opt_showUsersHistory='false'
opt_since=$($date_exec --date="1 day ago" +%F)
opt_until=$($date_exec --date="today" +%F)
opt_verbose='false'


while getopts 'aps:u:v' flag; do
    case "${flag}" in
        a) opt_update='true' ;;
        p) opt_pauseOnGrayCommit='true' ;;
        s) opt_since="$($date_exec --date="$OPTARG" +%F)" ;;
        u) opt_until="$($date_exec --date="$OPTARG" +%F)" ;;
        v) opt_verbose='true' ;;
        *) error "Unexpected option ${flag}" ;;
    esac
done

sinceNumber=$($date_exec --date="$opt_since" +%F | sed "s/-//g")
sinceMinusBase=$($date_exec -d "$($date_exec -d "$opt_since" +%F)- 3 month" +%F)



function countInsertions {
    declare -a users=("${!1}")
    usersWithCounts=()
    userI=0

    cd ..

    if [[ $opt_update == 'true' ]]; then

        for folder in ./*; do
            if [ -d "$folder" ]; then
                cd $folder
                echo "updating $folder"
                git reset --hard
                git pull --rebase
                echo "done updating $folder"
                cd ..
            fi
        done
    fi

    for folder in ./*; do
        if [ -d "$folder" ]; then
            cd $folder
            echo ""
            echo ""
            echo ""
            echo ""
            echo ""
            echo "$folder"


            for user in "${users[@]}"
            do
                gitResponse=$(git log --reverse --shortstat --pretty=format:"%H %ae:::" --all --no-merges --ignore-space-at-eol -w --since="$opt_since" --until="$opt_until" --author="$user" --diff-filter=AM | sed -e ':a' -e 'N' -e '$!ba' -e 's/:::\n/ /g' | awk ' {print $6 + $8} ')
                userSummaryCounter=0
                for count in $gitResponse
                do
                    let "userSummaryCounter= $userSummaryCounter + $count"
                done


                userDescNSum=()
                gitAuthorsBase=$(git log --reverse --shortstat --pretty=format:"%H %ad %ae:::" --all --no-merges --ignore-space-at-eol -w --since="$sinceMinusBase" --until="$opt_since" --author="$user" --date="short" --diff-filter=AM | grep "\w" | sed -e ':a' -e 'N' -e '$!ba' -e 's/:::\n/ /g' | awk ' {print $1 "_" $2 "_" $3 "_" $7 + $9} ')
                gitMessagesBase=($(git log --reverse --pretty=format:"%s" --all --no-merges --ignore-space-at-eol -w --since="$sinceMinusBase" --until="$opt_since" --author="$user" --date="short" --diff-filter=AM | sed 's/ /_/g' | awk ' {print $1} '))
                commitIBase=0
                for count in $gitAuthorsBase
                do
                    data=(${count//_/ })
                    brHash=${data["0"]}
                    date=${data["1"]}
                    dateNumber=$($date_exec --date="$date" +%F | sed "s/-//g")
                    author=${data["2"]}
                    sum=${data["3"]}
                    desc=${gitMessagesBase[$commitIBase]}
                    descNSum=$sum$desc

                    userDescNSum[$commitIBase]="$descNSum"
                    let "commitIBase= $commitIBase + 1"
                done


                gitAuthors=$(git log --reverse --shortstat --pretty=format:"%H %ad %ae:::" --all --no-merges --ignore-space-at-eol -w --since="$opt_since" --until="$opt_until" --author="$user" --date="short" --diff-filter=AM | grep "\w" | sed -e ':a' -e 'N' -e '$!ba' -e 's/:::\n/ /g' | awk ' {print $1 "_" $2 "_" $3 "_" $7 + $9} ')
                gitMessages=($(git log --reverse --pretty=format:"%s" --all --no-merges --ignore-space-at-eol -w --since="$opt_since" --until="$opt_until" --author="$user" --date="short" --diff-filter=AM | sed 's/ /_/g' | awk ' {print $1} '))
                userFiltredCounter=0
                userTrusedCounter=0
                userUntrustedCounter=0
                userUndecidedCounter=0
                userNotUniqCounter=0
                commitI=0
                for count in $gitAuthors
                do
                    data=(${count//_/ })
                    brHash=${data["0"]}
                    date=${data["1"]}
                    dateNumber=$($date_exec --date="$date" +%F | sed "s/-//g")
                    author=${data["2"]}
                    sum=${data["3"]}
                    desc=${gitMessages[$commitI]}
                    descNSum=$sum$desc


                    commitTrustState=$(commitIsTrusted $brHash)
                    commitUnTrustState=$(commitIsUnTrusted $brHash)
                    commitDestNSumNotUniq=$(containsElement $descNSum "${userDescNSum[@]}")

                    sizeLimit=200


                    if [ "$sinceNumber" -le "$dateNumber" ]
                    then

                        if [ "$commitDestNSumNotUniq" == "false" ]; then

                            if [[ "$sum" -lt "$sizeLimit" ]] || [ "$commitTrustState" == "true" ]; then
                                let "userFiltredCounter= $userFiltredCounter + $sum"

                                if [ "$commitTrustState" == "true" ]; then
                                    echo "$(tput setaf 2)more than $sizeLimit:" $brHash $author $date "("$sum")"
                                    echo $(tput setaf 2)${gitMessages[$commitI]}$(tput sgr0)
                                    echo ""
                                fi
                            else

                                if [ "$commitUnTrustState" == "true" ]; then
                                    let "userUntrustedCounter= $userUntrustedCounter + $sum"
                                    echo "$(tput setaf 1)more than $sizeLimit:" $brHash $author $date "("$sum")"
                                    echo $(tput setaf 1)${gitMessages[$commitI]}$(tput sgr0)
                                    echo ""
                                else
                                    echo "more than $sizeLimit:" $brHash $author $date "("$sum")"
                                    echo ${gitMessages[$commitI]}
                                    if [[ $opt_pauseOnGrayCommit == 'true' ]]; then
                                        echo -e "\n\n\n\n"
                                        echo "$(tput setaf 6)DETAILS: ==================================================================$(tput sgr0)"
                                        echo -e "\n"
                                        echo "counter        : $sum"
                                        echo "author         : $author"
                                        echo "date           : $date"
                                        echo "commit message : ${gitMessages[$commitI]}"
                                        echo "link           : $(tput setaf 3)https://gitlab.com/digitarium/$folder/-/commit/$brHash$(tput sgr0)"
                                        echo -e "\n\n$(tput setaf 6)ON HOLD$(tput sgr0)"

                                        read -r -n 1 -p "Is it trusted? [y/n/any key for skipping] " response
                                        case $response in
                                            [yY])
                                                echo ""
                                                echo "adding as trusted"
                                                echo "$brHash" >> ../george/commits_trusted.list
                                                let "userFiltredCounter= $userFiltredCounter + $sum"
                                                ;;
                                            [nN])
                                                echo ""
                                                echo "adding as untrusted"
                                                echo "$brHash" >> ../george/commits_untrusted.list
                                                let "userUntrustedCounter= $userUntrustedCounter + $sum"
                                                ;;
                                            *)
                                                let "userUndecidedCounter= $userUndecidedCounter + $sum"
                                                echo "skipping"
                                                ;;
                                        esac
                                    else
                                        let "userUndecidedCounter= $userUndecidedCounter + $sum"
                                    fi
                                    echo ""

                                fi
                            fi
                        else
                            let "userNotUniqCounter= $userNotUniqCounter + $sum"
                            if [ $opt_verbose == "true" ] || [[ "$sum" -gt "$sizeLimit" ]]; then
                                echo "$(tput setaf 5)seems not uniq:" $brHash $author $date "("$sum")"$(tput sgr0)
                                echo $(tput setaf 5)${gitMessages[$commitI]}$(tput sgr0)
                                echo ""
                            fi
                        fi
                    fi
                    userDescNSum[$commitIBase + $commitI]="$descNSum"
                    let "commitI= $commitI + 1"
                done


                if [[ "$userSummaryCounter" -gt "0" ]]; then

                    # RESUME BY USER IN A FLOW STATE
                    echo "$(tput setaf 6)$user $userFiltredCounter $userSummaryCounter$(tput sgr0)"
                    echo -e "\n\n\n\n"

                    # COLORING FINAL COUNTER
                    lineUndecidedHeader="undecided"
                    lineTrustedHeader="trusted"
                    lineUntrustedHeader="untrusted"
                    lineNotUniqHeader="not uniq"
                    lineSumHeader="summary"
                    if [[ "$userUndecidedCounter" -gt "0" ]]; then
                      lineUndecided="$(tput setaf 1)$userUndecidedCounter$(tput sgr0)"
                    else
                      lineUndecided="$(tput setaf 2)$userUndecidedCounter$(tput sgr0)"
                    fi
                    if [[ "$userFiltredCounter" -gt "0" ]]; then
                      lineTrusted="$(tput setaf 2)$userFiltredCounter$(tput sgr0)"
                    else
                      lineTrusted="$(tput setaf 1)$userFiltredCounter$(tput sgr0)"
                    fi
                    if [[ "$userUntrustedCounter" -gt "0" ]]; then
                      lineUntrusted="$(tput setaf 3)$userUntrustedCounter$(tput sgr0)"
                    else
                      lineUntrusted="$userUntrustedCounter"
                    fi
                    if [[ "$userNotUniqCounter" -gt "0" ]]; then
                      lineNotUniq="$(tput setaf 5)$userNotUniqCounter$(tput sgr0)"
                    else
                      lineNotUniq="$userNotUniqCounter"
                    fi
                    lineSum="$userSummaryCounter"
                    lineFolder="$(tput setaf 6)$folder$(tput sgr0)"

                    finalColoredLine="$user $lineFolder
                    \n$lineTrustedHeader: $lineTrusted, $lineUndecidedHeader: $lineUndecided
                    \n$lineSumHeader: $lineSum, $lineUntrustedHeader: $lineUntrusted, $lineNotUniqHeader: $lineNotUniq\n"

                    usersWithCounts[$userI]="$finalColoredLine"
                fi

                let "userI= $userI + 1"
            done

            cd ..
        fi
    done

    echo -e "\n\n\n\n\n\n\n"
    echo "$(tput setaf 6)================ FINAL COUNTER ================$(tput sgr0)"
    echo "$(tput setaf 6)from $opt_since to $opt_until$(tput sgr0)"
    echo ""
    for k in "${!usersWithCounts[@]}"
    do
        echo -e  ${usersWithCounts["$k"]}
    done
    echo "$(tput setaf 6)===============================================$(tput sgr0)"
}


function countByFakeDate {
    declare -a users=("${!1}")
    usersWithCounts=()
    userI=0
    for user in "${users[@]}"
    do
        N=0
        dates=()
        users=()
        for i in $(git log --pretty=format:"%ad" --reverse --date=short --all --no-merges --since="$opt_since" --until="$opt_until" --author="$user" | sed 's/-//g') ; do
              dates[$N]="$i"
          let "N= $N + 1"
        done

        quantity=0
        for date in "${dates[@]}"
        do
            if [ "$sinceNumber" -le "$date" ]
            then
                let "quantity= $quantity + 1"
            fi
        done

        usersWithCounts[$userI]="$quantity, $user, (sanitazed from: $N)"
        let "userI= $userI + 1"
    done

    for k in "${!usersWithCounts[@]}"
    do
        echo  ${usersWithCounts["$k"]}
    done |
    sort -rn -k1
}




function commitIsTrusted() {
    hash="${@:1}"

    while IFS=\= read TRUSTED_COMMIT; do
        TRUSTED_COMMITS+=($TRUSTED_COMMIT)
    done < ../george/commits_trusted.list
    trustedCommits=(${TRUSTED_COMMITS[@]})

    echo $(containsElement $hash ${trustedCommits[@]})
}


function commitIsUnTrusted() {
    hash="${@:1}"
    while IFS=\= read UNTRUSTED_COMMIT; do
        UNTRUSTED_COMMITS+=($UNTRUSTED_COMMIT)
    done < ../george/commits_untrusted.list
    untrustedCommits=(${UNTRUSTED_COMMITS[@]})

    echo $(containsElement $hash ${untrustedCommits[@]})
}

containsElement () {
    local e
    for e in "${@:2}"; do [[ "$e" == "$1" ]] && echo "true" && return 0; done
    echo "false"
}


function printData() {
    declare -a usersData=("${!1}")
    committers=(${usersData[@]})

    echo ""
    echo ""
    echo ""
    echo -en "\033[37;1;41m $2, for $opt_since -- $opt_until \033[0m"
    echo ""
    echo ""
    echo ""
    echo "$(tput setaf 6)Big commits $(tput sgr0)"
    countInsertions committers[@]
    echo ""
    echo ""
    echo ""
    echo ""
    echo ""
}

while IFS=\= read FILE_USER; do
    #shielding users for usage in git log params
    name=$(echo "$FILE_USER"  | sed 's/|/\\|/g; s/(/\\(/g; s/)/\\)/g')
    FILE_USERS+=($name)
done < users.list
printData FILE_USERS[@] 'Front'
