import strawberry
from typing import List, Optional
from api.db import get_session
import Levenshtein
from api.auth import get_current_user
from fastapi import Depends
from strawberry.permission import BasePermission
from strawberry.types import Info 
from jose import jwt, JWTError

@strawberry.input
class PersonInput:
    name: str
    gender: str
    father_name: str
    grandfather_name: str
    mother_name: Optional[str] = None
    isimp: bool
    notes: Optional[str] = ""

@strawberry.input
class DeletePersonInput:
    id: Optional[str] = None
    name: Optional[str] = None
    father_name: Optional[str] = None

@strawberry.type
class Person:
    id: str
    name: str
    father_name: Optional[str]
    grandfather_name: Optional[str]
    gender: str
    mother_name: Optional[str]
    isimp: Optional[bool]
    notes: Optional[str]

@strawberry.type
class Ancestor:
    id: str
    name: str
    gender: str
    father_name: str
    grandfather_name: str
    mother_name: Optional[str]

class IsAuthenticated(BasePermission):
    async def has_permission(self, source, info: Info, **kwargs) -> bool:
        request = info.context["request"]
        token = request.headers.get("authorization", "").replace("Bearer ", "")
        try:
            jwt.decode(token, "ABC", algorithms=["HS256"])
            return True
        except JWTError:
            return False

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
                    father_name=record["p"].get("father_name"),
                    grandfather_name=record["p"].get("grandfather_name"),
                    gender=record["p"]["gender"],
                    mother_name=record["p"].get("mother_name"),
                    isimp=record["p"].get("isimp"),
                    notes=record["p"].get("notes")
                )
                for record in result
            ]

    @strawberry.field
    def trace_to_root(self, name: str, father_name: str) -> List[Ancestor]:
        with get_session() as session:
            result = session.run("""
                MATCH path = (p:Person)-[:SON_OF|DAUGHTER_OF*]->(ancestor:Person)
                WHERE toLower(p.name) = toLower($name) AND toLower(p.father_name) = toLower($father_name)
                WITH path
                ORDER BY length(path) DESC
                LIMIT 1
                UNWIND nodes(path) AS n
                RETURN DISTINCT n
            """, {"name": name, "father_name": father_name})

            return [
                Ancestor(
                    id=node["n"]["id"],
                    name=node["n"]["name"],
                    gender=node["n"]["gender"],
                    father_name=node["n"].get("father_name"),
                    grandfather_name=node["n"].get("grandfather_name"),
                    mother_name=node["n"].get("mother_name")
                )
                for node in result
            ]

@strawberry.type
class Mutation:
    @strawberry.mutation(permission_classes=[IsAuthenticated]) 
    async def create_person(self, person: PersonInput) -> Person:
        with get_session() as session:
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

            if not actual_grandfather:
                raise Exception(f"Father '{person.father_name}' has no recorded father")
            if actual_grandfather.lower() != person.grandfather_name.lower():
                raise Exception(f"Grandfather mismatch: Expected '{actual_grandfather}', got '{person.grandfather_name}'")

            similar_name_result = session.run("""
                MATCH (p:Person)
                WHERE toLower(p.father_name) = toLower($father_name)
                RETURN p.name AS existing_name
            """, {"father_name": person.father_name})

            for record in similar_name_result:
                existing_name = record["existing_name"]
                distance = Levenshtein.distance(person.name.lower(), existing_name.lower())
                if distance <= 2:
                    raise Exception(f"A similar person '{existing_name}' already exists with the same father name")

            result = session.run("""
                CREATE (p:Person {
                    id: randomUUID(),
                    name: $name,
                    gender: $gender,
                    father_name: $father_name,
                    grandfather_name: $grandfather_name,
                    mother_name: $mother_name,
                    isimp: $isimp,
                    notes: $notes
                })
                RETURN p
            """, {
                "name": person.name,
                "gender": person.gender,
                "father_name": person.father_name,
                "grandfather_name": person.grandfather_name,
                "mother_name": person.mother_name,
                "isimp": person.isimp,
                "notes": person.notes
            })

            created = result.single()["p"]

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
                father_name=created.get("father_name"),
                grandfather_name=created.get("grandfather_name"),
                mother_name=created.get("mother_name"),
                isimp=created.get("isimp"),
                notes=created.get("notes")
            )

    @strawberry.mutation(permission_classes=[IsAuthenticated])
    def delete_person(self, person: DeletePersonInput) -> str:
        with get_session() as session:
            if person.id:
                match_query = """
                    MATCH (p:Person)
                    WHERE toLower(p.id) = toLower($id)
                    RETURN p
                """
                params = {"id": person.id}
            elif person.name and person.father_name:
                match_query = """
                    MATCH (p:Person)
                    WHERE toLower(p.name) = toLower($name)
                      AND toLower(p.father_name) = toLower($father_name)
                    RETURN p
                """
                params = {
                    "name": person.name,
                    "father_name": person.father_name
                }
            else:
                raise Exception("Provide either id OR both name and father_name to delete the person.")

            match_result = session.run(match_query, params).single()
            if not match_result:
                raise Exception("No matching person found to delete.")

            person_node = match_result["p"]
            person_id = person_node["id"]

            child_check = session.run("""
                MATCH (p:Person)<-[:SON_OF|DAUGHTER_OF]-(c:Person)
                WHERE toLower(p.id) = toLower($id)
                RETURN count(c) as child_count
            """, {"id": person_id})

            if child_check.single()["child_count"] > 0:
                raise Exception("Cannot delete this person because they have children.")

            delete_result = session.run("""
                MATCH (p:Person)
                WHERE toLower(p.id) = toLower($id)
                DETACH DELETE p
                RETURN COUNT(*) AS deleted
            """, {"id": person_id})

            if delete_result.single()["deleted"] == 0:
                raise Exception("Deletion failed.")
            return "Person deleted successfully."

schema = strawberry.Schema(query=Query, mutation=Mutation)