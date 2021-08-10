#!/usr/bin/env bash
#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#


export SPARK_DIST_CLASSPATH=$({{ hadoop_home }}/bin/hadoop classpath)
export HADOOP_CONF_DIR={{ hadoop_home }}/etc/hadoop
export LD_LIBRARY_PATH=$HADOOP_HOME/lib/native:$LD_LIBRARY_PATH
export PLATFORM_VERSION=2.11_spark2.4
export DATAGEN_VERSION=0.4.0-SNAPSHOT
export SPARK_APPLICATION_MAIN_CLASS=ldbc.snb.datagen.spark.LdbcDatagen
export SPARK_DAEMON_JAVA_OPTS="-Dspark.deploy.recoveryMode=ZOOKEEPER  -Dspark.deploy.zookeeper.url={{ zookeeper_connect }}"
