## Usage 
```
chef exec ruby get_data.rb --orgs org1,org2 --node-threshold 45 --knife-config /home/myuser/.chef/knife.rb
```

The script will put JSON reports in an `output` directory in the same directory as the script.
* `<org>_<threshold_num>d_stale_nodes.json` - Nodes in that org that have not checked in for the number of days specified.
* `<org>_cookbook_count.json` - Number of cookbook versions for each cookbook that that org.
* `<org>_unused_cookbooks.json` - A list of cookbooks and version that do not appear to be in-use for that org.  This is determined by checking the versioned run list of each of the nodes in the org.

## Options
* `--orgs` -> A comma separated list of orgs to process
* `--all-orgs` -> Processes all orgs on the chef server.  Setting this will override the `--orgs` setting
* `--node-threshold` -> Takes an integer specifying the number of days since last checkin to mark a node as stale.
* `--knife-config` -> A path to the knife config for the script to use.  If using `--all-orgs`, this must be the pivotal user.  If processing multiple orgs, must be pivotal or another user that can access all the specified orgs.
