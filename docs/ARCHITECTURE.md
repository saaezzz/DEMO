Architecture
Engine
Roblox

Language
Luau

Architecture
Client / Server

Server Authority
The server is authoritative over all gameplay-critical state.

Client Responsibilities
Input
Camera
UI
Local visual effects
Animation presentation

Server Responsibilities
Combat validation
Damage
Player state
Inventory
Economy
NPC state
Persistence

Shared
Types
Constants
Configuration
Pure utilities

Design Principles
Prefer composition over deep inheritance.
Use typed Luau.
Keep modules focused.
Validate all client requests on the server.
Avoid global mutable state.
Do not duplicate business logic between client and server.