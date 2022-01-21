# Advanced HDFS configurations using Muchos
Muchos optionally sets up advanced HDFS scenarios, including highly-available configuration using the [Quorum Journal Manager](https://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-hdfs/HDFSHighAvailabilityWithQJM.html), and multiple HDFS volumes.

## Configuring HDFS High-Availability
By default Muchos will deploy a standalone HDFS configuration without any high-availability (HA). To configure HA for HDFS, first set the `hdfs_ha` parameter to True in muchos.props. Then, when using `azure` cluster type, the Muchos `launch` step pre-populates the `nodes` section in muchos.props with the necessary roles for a HA configuration. For all cluster types you can manually do the same by providing the appropriate roles in muchos.props under the `nodes` section. Here is a sample HA configuration:
```
testcluster-0 = namenode,resourcemanager,accumulomaster,zookeeper,journalnode,zkfc
testcluster-1 = zookeeper,journalnode,namenode,zkfc,accumulomaster,resourcemanager
testcluster-2 = journalnode,zookeeper
testcluster-3 = worker
testcluster-4 = worker
testcluster-5 = worker
```

## Configuring multiple HDFS volumes (namespaces)
By default, Muchos sets up a single HDFS volume (namespace) with a nameservice ID specified in muchos.props. For dev / test scenarios, it may be required to configure, and use, multiple HDFS volumes for Accumulo.
By default, Muchos uses the nameservice_id specified under the default section of muchos.props, to configure a single HDFS volume. To configure multiple such HDFS volumes / namespaces, simply add the name of the nameservice ID (that services deployed on a node will be associated with) against each node under the `nodes` section in muchos.props. As an example, the configuration below sets up 2 namespaces `ns1` and `ns2`, each of which has its own set of 'leader' role nodes, including a separate Zookeeper:
```
testcluster-0 = namenode,resourcemanager,accumulomaster,zookeeper ns1
testcluster-1 = worker ns1
testcluster-2 = worker ns1
testcluster-3 = worker ns1
testcluster-4 = namenode,resourcemanager,zookeeper ns2
testcluster-5 = worker ns2
testcluster-6 = worker ns2
testcluster-7 = worker ns2
```
As can be seen above, the nameservice ID is simply suffixed after the list of roles for each node, with a whitespace delimiter in between. If the nameservice ID is not specified for a given node, it will be defaulted to the value specified in nameservice_id under the 'default' section in muchos.props.

For Azure based clusters, there is an integration with the "multiple VMSS" mode of deployment, wherein each VMSS can have a nameservice_id associated with it. This eliminates the need to manually edit the muchos.props file to assign nameservice_ids to each node. Please see [Multiple VMSS based deployments in Azure](./azure-multiple-vmss.md) for more details.

## Dedicating Zookeeper instances for Accumulo usage
Muchos by default is set to use a nameservice_id called 'accucluster'. In addition, there is a parameter called `accumulo_zk_nameservice_id` in muchos.props, which defaults to 'accucluster'. This parameter is used by Muchos to identify which Zookeeper node(s) to use for Accumulo. It is possible to set this parameter to a different 'nameservice ID', and thereby dedicate Zookeeper node(s) for exclusive use by Accumulo. As an example, by setting `accumulo_zk_nameservice_id = acczk` and using the below entries in the 'nodes' section of muchos.props, Accumulo will exclusively use Zookeeper on testcluster-8.
```
testcluster-0 = namenode,resourcemanager,accumulomaster ns1
testcluster-1 = worker ns1
testcluster-2 = worker ns1
testcluster-3 = worker ns1
testcluster-4 = namenode,resourcemanager ns2
testcluster-5 = worker ns2
testcluster-6 = worker ns2
testcluster-7 = worker ns2
testcluster-8 = zookeeper acczk
```
In the above configuration, Accumulo is automatically configured by Muchos to use multiple HDFS volumes:
```
instance.volumes=hdfs://ns1/accumulo,hdfs://ns2/accumulo
```
Also, shown below is output clearly showing how Accumulo is able to use both HDFS volumes:
```
$ hdfs dfs -ls hdfs://ns1/accumulo/tables
Found 1 items
drwxr-xr-x   - centos supergroup          0 2020-06-30 06:50 hdfs://ns1/accumulo/tables/3
$ hdfs dfs -ls hdfs://ns2/accumulo/tables
Found 4 items
drwxr-xr-x   - centos supergroup          0 2020-06-30 06:44 hdfs://ns2/accumulo/tables/!0
drwxr-xr-x   - centos supergroup          0 2020-06-30 06:44 hdfs://ns2/accumulo/tables/+r
drwxr-xr-x   - centos supergroup          0 2020-06-30 06:44 hdfs://ns2/accumulo/tables/+rep
drwxr-xr-x   - centos supergroup          0 2020-06-30 06:44 hdfs://ns2/accumulo/tables/1
```

## Sample configuration with High-Availability for HDFS and Accumulo, multiple HDFS volumes and dedicated Zookeeper for Accumulo
Here is a sample configuration combining the various advanced configs mentioned previously. The below configuration deploys two highly-available HDFS volumes (namespace IDs `ns1` and `ns2` and dedicates a set of 3 Zookeepers for exclusive use by Accumulo):
```
testcluster-0 = namenode,resourcemanager,zookeeper,journalnode,zkfc ns1
testcluster-1 = zookeeper,journalnode,namenode,zkfc,resourcemanager ns1
testcluster-2 = journalnode,zookeeper ns1
testcluster-3 = worker ns1
testcluster-4 = worker ns1
testcluster-5 = worker ns1
testcluster-6 = namenode,resourcemanager,zookeeper,journalnode,zkfc ns2
testcluster-7 = zookeeper,journalnode,namenode,zkfc,resourcemanager ns2
testcluster-8 = journalnode,zookeeper ns2
testcluster-9 = worker ns2
testcluster-10 = worker ns2
testcluster-11 = worker ns2
testcluster-12 = zookeeper acczk
testcluster-13 = zookeeper acczk
testcluster-14 = zookeeper acczk
testcluster-15 = accumulomaster ns1
testcluster-16 = accumulomaster ns2
```
Here's the Zookeeper configuration within accumulo.properties:
```
instance.zookeeper.host=testcluster-12:2181,testcluster-13:2181,testcluster-14:2181
```

## Spark workloads and namespace tagging
Currently, the `spark` service causes the Spark tarball to be copied and extracted on all `worker` nodes. The node specifically tagged with the `spark` service hosts the Spark History server in addition to any other roles it was assigned with. Hence, this means that tagging the node which was assigned the `spark` service, with a nameservice_id just means that that node will serve as the Spark History server for spark jobs running in the context of YARN associated with that HDFS namespace. As a corollary, tagging a nameservice_id to the node containing with the `spark` service, does not *prevent* running Spark jobs on YARN associated with other namespaces - it just means that the Spark History service will not be spun up correspondingly for those (other) namespaces.

## Using HDFS Federation with multiple HDFS namespaces
TODO for a later PR - optionally allow configuring the HDFS name nodes to enroll in all namespaces, thereby participating in federation.

## Selectively using HDFS volume(s) for usage by Accumulo
TODO for a later PR - allow (optionally) specifying which namespaces are used by Accumulo for HDFS storage
