import strawberry
from typing import List, Optional
from api.db import get_session

@strawberry.input
class PersonInput:
    name: str
    gender: str
    father_name: str
    grandfather_name: str
    mother_name: Optional[str] = None

@strawberry.type
class Person:
    id: str
    name: str
    father_name: str
    grandfather_name: str
    gender: str
    mother_name: Optional[str]

@strawberry.type
class Mutation:
    @strawberry.mutation
    def create_person(self, person: PersonInput) -> Person:
        with get_session() as session:
            # 1. Check if father exists (case-insensitive)
            father_result = session.run("""
                MATCH (f:Person)
                WHERE toLower(f.name) = toLower($father_name)
                RETURN f
            """, {"father_name": person.father_name})
            
            father_record = father_result.single()
            if not father_record:
                raise Exception(f"Father '{person.father_name}' not found")

            father_node = father_record["f"]
            actual_grandfather = father_node.get("father_name")

            # 2. Validate grandfather name
            if not actual_grandfather:
                raise Exception(f"Father '{person.father_name}' has no recorded father")
            if actual_grandfather.lower() != person.grandfather_name.lower():
                raise Exception(
                    f"Grandfather mismatch: Expected '{actual_grandfather}', got '{person.grandfather_name}'"
                )

            # 3. Check for duplicate person
            duplicate_check = session.run("""
                MATCH (p:Person)
                WHERE toLower(p.name) = toLower($name)
                  AND toLower(p.father_name) = toLower($father_name)
                  AND toLower(p.grandfather_name) = toLower($grandfather_name)
                RETURN p
            """, {
                "name": person.name,
                "father_name": person.father_name,
                "grandfather_name": person.grandfather_name
            })

            if duplicate_check.single():
                raise Exception("Person already exists with the same name, father name, and grandfather name")

            # 4. Create the new person
            result = session.run("""
                CREATE (p:Person {
                    id: randomUUID(),
                    name: $name,
                    gender: $gender,
                    father_name: $father_name,
                    grandfather_name: $grandfather_name,
                    mother_name: $mother_name
                })
                RETURN p
            """, {
                "name": person.name,
                "gender": person.gender,
                "father_name": person.father_name,
                "grandfather_name": person.grandfather_name,
                "mother_name": person.mother_name,
            })

            created = result.single()["p"]

            # 5. Create relationship to father using MERGE to avoid duplicates
            relation = "SON_OF" if person.gender.lower() in ["male", "m"] else "DAUGHTER_OF"
            session.run(f"""
                MATCH (child:Person)
                WHERE toLower(child.name) = toLower($child_name)
                MATCH (father:Person)
                WHERE toLower(father.name) = toLower($father_name)
                MERGE (child)-[:{relation}]->(father)
            """, {
                "child_name": person.name,
                "father_name": person.father_name,
            })

            return Person(
                id=created["id"],
                name=created["name"],
                gender=created["gender"],
                father_name=created["father_name"],
                grandfather_name=created["grandfather_name"],
                mother_name=created.get("mother_name")
            )

@strawberry.type
class Query:
    @strawberry.field
    def all_persons(self) -> List[Person]:
        with get_session() as session:
            result = session.run("MATCH (p:Person) RETURN p")
            return [
                Person(
                    id=record["p"]["id"],
                    name=record["p"]["name"],
                    father_name=record["p"]["father_name"],
                    grandfather_name=record["p"]["grandfather_name"],
                    gender=record["p"]["gender"],
                    mother_name=record["p"].get("mother_name")
                )
                for record in result
            ]

# ✅ Final schema
schema = strawberry.Schema(query=Query, mutation=Mutation)
