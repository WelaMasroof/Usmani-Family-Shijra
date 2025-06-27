import strawberry
from typing import List, Optional
from db import get_session

@strawberry.type
class Person:
    id: str
    name: str
    father_name: str
    grandfather_name: str
    mother_name: Optional[str]

    @strawberry.field
    def children(self) -> List["Person"]:
        with get_session() as session:
            result = session.run("""
                MATCH (p:Person)<-[:SON_OF|DAUGHTER_OF]-(c:Person)
                WHERE p.id = $id
                RETURN c
            """, id=self.id)
            return [
                Person(**record["c"])
                for record in result
            ]

@strawberry.type
class Query:
    @strawberry.field
    def all_persons(self) -> List[Person]:
        with get_session() as session:
            result = session.run("MATCH (p:Person) RETURN p")
            people = []
            for record in result:
                print(record)  # Debug output
                node = record["p"]
                print(node.items())  # See what’s inside the node
                people.append(Person(
                    id=node["id"],
                    name=node["name"],
                    father_name=node["father_name"],
                    grandfather_name=node["grandfather_name"],
                    mother_name=node.get("mother_name")  # Optional field
                ))
            return people

schema = strawberry.Schema(Query)
