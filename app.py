import streamlit as st
import pandas as pd
import plotly.express as px
from sklearn.linear_model import LogisticRegression

st.set_page_config(page_title="Pass or Fail Predictor", page_icon="🎓", layout="wide")

st.markdown("""
<style>
.main-title{font-size:2.3rem;font-weight:800;margin-bottom:0}
.sub{color:#64748b;font-size:1rem;margin-bottom:1.5rem}
</style>
""", unsafe_allow_html=True)

st.markdown('<div class="main-title">🎓 Student Pass or Fail Predictor</div>', unsafe_allow_html=True)
st.markdown('<div class="sub">Logistic Regression • Study-hours based educational ML demonstration</div>', unsafe_allow_html=True)

data={"Hours":[1,2,3,4,5,6],"Pass":[0,0,0,1,1,1]}
df=pd.DataFrame(data)
model=LogisticRegression()
model.fit(df[["Hours"]],df["Pass"])

c1,c2,c3=st.columns(3)
c1.metric("Training Records",len(df))
c2.metric("Model","Logistic Regression")
c3.metric("Feature","Study Hours")

st.divider()
left,right=st.columns([1,1.35])

with left:
    st.subheader("Student Input")
    hours=st.number_input("Study Hours",min_value=0.0,max_value=24.0,value=4.5,step=0.5)
    if st.button("📊 Predict Result",type="primary",use_container_width=True):
        pred=int(model.predict([[hours]])[0])
        prob=float(model.predict_proba([[hours]])[0][1])
        st.session_state["result"]=(pred,prob,hours)

    if "result" in st.session_state:
        pred,prob,h=st.session_state["result"]
        st.subheader("Prediction Result")
        if pred:
            st.success(f"Student will PASS\n\nEstimated pass probability: {prob:.1%}")
        else:
            st.error(f"Student will FAIL\n\nEstimated pass probability: {prob:.1%}")
        st.progress(prob,text=f"Pass probability: {prob:.1%}")

with right:
    st.subheader("Training Data")
    plot=df.copy()
    plot["Status"]=plot["Pass"].map({0:"Fail",1:"Pass"})
    fig=px.scatter(plot,x="Hours",y="Pass",color="Status",title="Study Hours vs Pass/Fail")
    fig.update_yaxes(tickvals=[0,1],ticktext=["Fail","Pass"])
    st.plotly_chart(fig,use_container_width=True)

st.subheader("Dataset Preview")
st.dataframe(df.assign(Pass=df["Pass"].map({0:"Fail",1:"Pass"})),use_container_width=True,hide_index=True)

st.warning("Educational prototype: real academic performance depends on many factors beyond study hours.")
