📘 syntax: DistroSourceTools.fn.sh --{system|custom}-config-option <operation>

##  Arguments:

		None. This command is option-driven.

##  Options:

		--all-namespaces
		--list-namespaces
		--list-repository-roots
		--list-namespace-roots
			Lists names of currently registered root namespaces and exits.

		--all-source-namespaces
			Lists source namespaces discovered directly from current source tree scan and exits.

		--register-repository-root <namespace-root-name> <distro-fetch-url>|--not-set
		--register-namespace-root <namespace-root-name> <distro-fetch-url>|--not-set
			Registers the distro root namespace by (re-)creating corresponding directory
			in sources root and (re-)creating the `repository.inf` file. This is required
			for projects being pulled into that root to be treated as projects and exits.

		--unregister-repository-root <namespace-root-name>
		--unregister-namespace-root <namespace-root-name>
			Drops root namespace registration, removing root config from internal store 
			and removing `repository.inf` file from source tree. After that, source directories
			that are not under any registered namespace roots are ignored in source build 
			processes and exits.

		--register-repository-roots <namespace-root-name> [<namespace-root-name>...]
		--register-namespace-roots <namespace-root-name> [<namespace-root-name>...]
		--unregister-repository-roots <namespace-root-name> [<namespace-root-name>...]
		--unregister-namespace-roots <namespace-root-name> [<namespace-root-name>...]
			Registers and unregisters multiple namespace roots at ones. Uses '--not-set' as 
			namespace public distro fetch url and exits.

		--upgrade-source-tools
			Upgrades local source packages with latest `master` version and exits.
		
		--system-config-option <arguments...>
		--custom-config-option <arguments...>
			Sets the workspace environment parameter. 'system' is common for workspace and
			'custom' is for current workspace user. Performs requested config operation and exits.

			Following operations (arguments) are supported:

				--select <option-name>
				--select-default <option-name> <default-value>
					Reads one or all variables. If value is not set, default-value is returned.

				--select --all
				--select-all
					Reads all variables. 

				--upsert <option-name> <value>
				--upsert-if <option-name> <value> <if-value>
					Sets a variable. Optionally, sets variable only if it's current value
					is set to given value.

				--delete <option-name>
				--delete-if <option-name> <if-value>
					Deletes a variable. Optionally, deletes the variable only if it's value
					is set to given value.

			Shared config variables (implemented in LocalTools.Config.include and consumed
			across distro consoles):

				MDLT_CONSOLE_ORIGIN
					Supports values of ".local", "source" or absolute path to whatever workspace's
					".local" or "source" directory. This parameter is used (with some extra sanity
					checks) while detecting MDLT_ORIGIN context value.

				MDLT_CONSOLE_SCRIPT
					Shell script to include in console initialisation process. Allows to setup 
					extra commands or settings. Note: before including this script, $HOME/.bashrc
					will be included automatically, if present.

				MDLT_CONSOLE_HISTORY
					Defines where and how your interactive shell (Console) history is stored. The
					default setting is `workspace-personal`.

					Supported values:
					– workspace-personal: each user gets their own file under <workspace>/.local/home/$USER/.bash_history;
					– local-machine-home: write to a per-workspace file in $HOME (e.g. ~/.bash_history_<workspace>);
					– workspace-separate: each user gets separate own history files, one per each subsystem (if ant)
						under <workspace>/.local/home/$USER/.bash_history_{source,deploy,remote};
					– workspace-shared: everyone shares a single history at <workspace>/.local/.common_bash_history;
					– bash-default: same as user-default, explicitly resets to Bash’s standard ~/.bash_history;
					– user-default: leave history in the user’s default (whatever settings currently are, untouched).

					Based on this setting the scripts configure HISTFILE along with HISTCONTROL, 
					HISTSIZE, HISTFILESIZE and histappend to achieve the desired isolation or 
					sharing.

				MDLT_ACTIONS_SH_WRAP
					Shell command to wrap shell actions to execute. Allows to run actions on
					remote runner machine or add extra logging/notification, etc...

		--make-console-command [--quiet]
			Re-Creates DistroSourceConsole.sh script to be used as a command to quickly enter workspace 
			console and exits. 
			
			Won't output helpful information on files created and how to use those files, when 
			`--quiet` option specified.

		--make-console-script
			Prints source console script body (used by --make-console-command) and exits.

		--make-code-workspace [--quiet]
			Re-Creates <workspace-name>.code-workspace workspace file to be used with VS Code and exits.
			
			Won't output helpful information on files created and how to use those files, when 
			`--quiet` option specified.

		--make-workspace-integration-files [--quiet]
			Runs all `--make-*` commands (--make-console-command, --make-code-workspace), thus 
			(re-)creating all SourceConsole the user executable workspace commands and files and exits.
			
			Won't output helpful information on files created and how to use those files, when 
			`--quiet` option specified.

		--make-rebuild-namespace-roots
		--make-rebuild-repository-roots
			Synchronizes .local/roots/*.distro-namespace and source/*/repository.inf files and exits.

##  Environment Variables:

		Context variables used in source mode:

			MMDAPP
				Workspace root path.

			MDLT_ORIGIN
				Source root for distro command libraries and scripts.

			MDSC_INMODE
				Current console mode (source).

			MDSC_OPTION
				Current context option set (for example distro input mode).

			MDSC_SOURCE
				Current source path used by scan/register/rebuild operations.

			MDSC_CACHED
				Current cached metadata/index root path.

			MDSC_OUTPUT
				Current output/cache target root path.

			MDSC_DETAIL
				Debug verbosity control (<empty>, true, full).

##  Examples (in Local Console, within workspace context):

		# Upgrade source tooling from local installer scripts
		`DistroSourceTools.fn.sh --upgrade-source-tools`

		# Register namespace root myx in workspace metadata
		`DistroSourceTools.fn.sh --register-namespace-root myx`

		# Register multiple namespace roots in one command
		`DistroSourceTools.fn.sh --register-namespace-roots lib myx dev pub`

##  Examples (in OS default shell):

		# Show DistroSourceTools help from the OS shell
		`bash .local/myx/myx.distro-source/sh-scripts/DistroSourceTools.fn.sh --help`

		# Upgrade source tooling by invoking the local wrapper script path
		`bash .local/myx/myx.distro-.local/sh-scripts/DistroSourceTools.fn.sh --upgrade-source-tools`
