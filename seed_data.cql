// import character metadata

LOAD CSV WITH HEADERS FROM "file:///characters.csv" as row
MERGE (c:Character{name:row.title})
SET c.url = row.url,
    c.aliases = row.aliases,
    c.blood = row.blood,
    c.nationality = row.nationality,
    c.species = row.species,
    c.gender = row.gender
FOREACH (h in CASE WHEN row.house IS NOT NULL THEN [1] ELSE [] END | MERGE (h1:House{name:row.house}) MERGE (c)-[:BELONGS_TO]->(h1))
FOREACH (l in split(row.loyalty,',') | MERGE (g:Group{name:l}) MERGE (c)-[:LOYAL_TO]->(g))
FOREACH (f in split(row.family,',') | MERGE (f1:Character{name:f}) MERGE (c)-[t:FAMILY_MEMBER]->(f1));


// import interactions

LOAD CSV WITH HEADERS FROM "file:///rel_first_seen.csv" as row
MATCH (s:Character{name:row.source})
MATCH (t:Character{name:row.target})
MERGE (s)-[:INTERACTS]->(i:Interaction)-[:INTERACTS]->(t)
SET i.first_seen = toInteger(row.value);

//Run pagerank on interaction network

CALL gds.pageRank.write({
    nodeQuery:'MATCH (c:Character) RETURN id(c) as id',
    relationshipQuery:'MATCH (c1:Character)-[:INTERACTS]-()-[:INTERACTS]-(c2:Character)
                       RETURN id(c1) as source, id(c2) as target',
    writeProperty:'pagerank'

});

// Run Louvain on interaction network

CALL gds.louvain.write({
    nodeQuery:'MATCH (c:Character) RETURN id(c) as id',
    relationshipQuery:'MATCH (c1:Character)-[:INTERACTS]-()-[:INTERACTS]-(c2:Character)
                       RETURN id(c1) as source, id(c2) as target',
    writeProperty:'community'

});

//Create full text index on Character name property

CREATE FULLTEXT INDEX characterSearch FOR (n:Character) ON EACH [n.name];
