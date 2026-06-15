import os
import asyncio
import cognee

async def run_reindex():
    print("Initializing Cognee...")
    # Configure cognee client if needed
    # By default, cognee uses local sqlite/qdrant or configured values
    
    # Retrieve base directory path
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    print(f"Indexing directory: {base_dir}")
    
    try:
        # cognee.add registers files/directories to be indexed
        await cognee.add(base_dir)
        
        # cognee.make processes the added contents and builds the knowledge graph
        await cognee.make()
        print("Cognee index completed successfully!")
    except Exception as e:
        print(f"Error during Cognee indexing: {e}")

if __name__ == "__main__":
    asyncio.run(run_reindex())
