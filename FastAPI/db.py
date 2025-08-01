from neo4j import GraphDatabase

driver = GraphDatabase.driver(
    uri="neo4j+s://3ac3a9cd.databases.neo4j.io",
    auth=("neo4j", "")
)


def get_session():
    return driver.session()
