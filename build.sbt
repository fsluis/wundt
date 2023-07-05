
// Because of interoperability with the hadoop sequence files... (@ data module)
scalacOptions += "-target:jvm-1.7"
scalacOptions += "-Xlog-implicits"

javacOptions ++= Seq("-source", "1.7", "-target", "1.7")

scalaVersion := "2.11.12"  //current spark 2.4.3 installation uses 2.11.12
scalaVersion in ThisBuild := "2.11.12"

crossScalaVersions := Seq("2.11.12") //"2.10.5",

ivyScala := ivyScala.value map { _.copy(overrideScalaVersion = true) }

//http://stackoverflow.com/questions/7081194/changing-project-layout-in-sbt-0-10-x
resourceDirectory in Compile <<= baseDirectory(_ / "resources")

resourceDirectory in Test <<= baseDirectory(_ / "resources")

lazy val commonSettings = Seq(
        resolvers += Resolver.mavenLocal
)

lazy val common_java = project
  .in(file("common"))
  .settings(commonSettings)

lazy val common_scala = project
      .in(file("common-scala") )
      .settings(commonSettings)
//  .dependsOn(common)

lazy val spark_extkey = project
  .in(file("spark-extkey") )
  .settings(commonSettings)

lazy val common_spark =project
  .in( file("common-spark") )
  .dependsOn(common_scala, spark_extkey)
  .settings(commonSettings)

lazy val complexity_core = project
  .in( file("complexity-core") )
  .dependsOn(common_scala, common_java)
  .settings(commonSettings)

lazy val complexity_lucene = project
  .in( file("complexity-lucene3") )
  .dependsOn(complexity_core)
  .settings(commonSettings)

lazy val complexity_lm = project
  .in( file("complexity-lm") )
  .dependsOn(complexity_core, complexity_lucene)
  .settings(commonSettings)

lazy val complexity_stanford = project
  .in( file("complexity-stanford") )
  .dependsOn(complexity_core, complexity_lucene % "test->compile")
  .settings(commonSettings)

lazy val complexity_hyphen = project
  .in( file("complexity-hyphen") )
  .dependsOn(complexity_core, complexity_lucene % "test->test")
  .settings(commonSettings)

lazy val complexity_wordnet = project
  .in( file("complexity-wordnet") )
  .dependsOn(complexity_core)
  .settings(commonSettings)

lazy val integration = project
  .in( file("integration") )
  .dependsOn(common_spark % "test->test;compile->compile", complexity_core, complexity_lucene, complexity_stanford, complexity_hyphen, complexity_lm, complexity_wordnet)
  .settings(commonSettings)

// This is just to assemble all the tests into one fat jar that allows for live integration tests on the cluster
lazy val spark_test = project
  .in( file("spark-test") )
  .dependsOn(common_spark % "compile->test", integration % "compile->test")
  .settings(commonSettings)

// And this is to import data from various sources (e.g., Wikipedia)
lazy val data = project
  .in( file("data") )
  .dependsOn(integration, spark_extkey)
  .settings(commonSettings)

lazy val root = project
  .in( file(".") )
  .aggregate(common_java, common_scala, common_spark, complexity_core, complexity_lucene, complexity_lm, complexity_hyphen, complexity_stanford, complexity_wordnet, integration, spark_test, data, spark_extkey)
  .settings(commonSettings)

packagedArtifacts in file(".") := Map.empty
