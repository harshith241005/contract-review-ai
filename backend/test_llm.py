from langchain_community.chat_models import ChatOllama
from langchain_core.messages import HumanMessage
llm = ChatOllama(model='llama3', temperature=0)
msg = HumanMessage(content='What is the estimated fair market price for a used 2018 Honda Civic in good condition? Reply ONLY with JSON like {"estimated_price": 15000, "low": 13000, "high": 17000} with NO markdown formatting, NO backticks, and NO other text.')
print(llm.invoke([msg]).content)
