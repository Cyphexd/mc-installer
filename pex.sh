#!/bin/bash

log(){
	case $2 in
	   "debug") echo -e "[$2] $1";;
	   *) echo -e "[info] $1";;
	esac
}

log "parameter_1 => $1" "debug"
log "parameter_1 => $1" "info"

start_paper_tool(){
    log
}

is_installed(){
    # shellcheck disable=SC2046
    if [ $(dpkg-query -W -f='${Status}' $1 2>/dev/null | grep -c "ok installed") -eq 0 ];
    then
        log "Installing Requirement: $1" "info"
        case $1 in
        "adoptopenjdk-11-openj9")
            wget -qO - https://adoptopenjdk.jfrog.io/adoptopenjdk/api/gpg/key/public | sudo apt-key add -
            sudo add-apt-repository --yes https://adoptopenjdk.jfrog.io/adoptopenjdk/deb/
            sudo apt update
            sudo apt install adoptopenjdk-11-openj9 git curl patch -y
          ;;
        "git")
            sudo apt install git -y
            git config --global credential.helper store
            git config --global user.name "$git_username"
            git config --global user.email "$git_email"
        ;;
        *)
            sudo apt install $1 -y
            ;;
        esac
        clear
        log "checking: $1 - Installed!"
    else
        log "checking: $1 - OK!" "debug"
    fi

}

print_main_menu(){
    clear
    echo -e "*** Minimal Minecraft Server Management Tool v0.0.1 by Pex ***\n"
    echo -e " 0) Clone and Compile PaperMC 1.16.5"
    echo -e " 1) Compile PaperMC"

    # shellcheck disable=SC2034
    read -p "Enter option: " main_menu_option

}

cfg.parser () {
    fixed_file=$(cat $1 | sed 's/ = /=/g')  # fix ' = ' to be '='
    IFS=$'\n' && ini=( $fixed_file )              # convert to line-array
    ini=( ${ini[*]//;*/} )                   # remove comments
    ini=( ${ini[*]/#[/\}$'\n'cfg.section.} ) # set section prefix
    ini=( ${ini[*]/%]/ \(} )                 # convert text2function (1)
    ini=( ${ini[*]/=/=\( } )                 # convert item to array
    ini=( ${ini[*]/%/ \)} )                  # close array parenthesis
    ini=( ${ini[*]/%\( \)/\(\) \{} )         # convert text2function (2)
    ini=( ${ini[*]/%\} \)/\}} )              # remove extra parenthesis
    ini[0]=''                                # remove first element
    ini[${#ini[*]} + 1]='}'                  # add the last brace
    eval "$(echo "${ini[*]}")"               # eval the result
}

main(){
    # loading config
    cfg.parser "$PWD/config.ini"
    cfg.section.directories
    cfg.section.repo
	REQUIREMENTS=(
	    'git' 'curl' 'patch' 'adoptopenjdk-11-openj9' 'maven' 'htop'
	)
	log "Checking for Requirements $(IFS=', ' eval 'joined="${REQUIREMENTS[*]}"')"
	for req in "${REQUIREMENTS[@]}"; do
        log "checking: $req" "debug"
        # shellcheck disable=SC2086
        is_installed $req
    done
    log "checking: requirements - OK!"



    log "config.directories.base_dir => $base_dir" "debug"
    log "config.directories.base_dir => $paper_src_dir" "debug"
    log "config.repo.repo_url => $repo_url" "debug"
    log "config.repo.git_username => $git_username" "debug"
    log "config.repo.git_email => $git_email" "debug"

    while [ true ]; do
        print_main_menu
        #clear
        case $main_menu_option in
        0)
            log "Cloning PaperMC into $paper_src_dir" "info"
            git clone "$repo_url" "$paper_src_dir" > /dev/null 2>&1
            chmod +x "$paper_src_dir/paper"
            clear
            log "Building PaperMC jars..." "info"
            sleep 3
            bash -c "$paper_src_dir/paper jar"
          ;;
        1)
            clear
            log "Building PaperMC jars..." "info"
            sleep 3
            bash -c "$paper_src_dir/paper jar"
            ;;
        esac
        #clear
        log "done!" "info"
        read -p "Enter any key to go back to main menu" menu_back
    done


}

time main