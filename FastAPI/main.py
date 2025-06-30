import uvicorn
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from strawberry.fastapi import GraphQLRouter
from schema import schema

app = FastAPI()

# 🔹 Allow CORS for all origins (for development only)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Replace with your Flutter domain in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 🔹 GraphQL route
graphql_app = GraphQLRouter(schema)
app.include_router(graphql_app, prefix="/graphql")

# 🔹 Entry point
if __name__ == "__main__":
    uvicorn.run("main:app", reload=True)
