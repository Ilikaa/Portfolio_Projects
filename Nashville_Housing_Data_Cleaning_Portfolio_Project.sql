
--Checking data for completeness
Select*
From dbo.Nashville_Housing


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--STANDARDIZING DATE FORMAT

--adding new field 
Alter Table dbo.Nashville_Housing
Add SalesDateConverted Date

--converting datetime to date format and populating new field
Update dbo.Nashville_Housing
Set SalesDateConverted = CONVERT(Date,SaleDate)


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--POPULATING PROPERTY ADDRESS DATA WHERE NULL

--viewing null entries in property address field
Select *
From dbo.Nashville_Housing
Where PropertyAddress is null

-- null entries share the same parcel id and owner name with other entries that have property address mentioned but have different unique ids.
Select *
From dbo.Nashville_Housing
Order by ParcelID

--creating a self join to use property address of non null entries for populating null entries sharing the same Parcel ID
Select Housing_1.ParcelID, Housing_1.PropertyAddress, Housing_2.ParcelID, Housing_2.PropertyAddress, ISNULL(Housing_1.PropertyAddress, Housing_2.PropertyAddress)
From dbo.Nashville_Housing as Housing_1
join dbo.Nashville_Housing as Housing_2
	on Housing_1.ParcelID = Housing_2.ParcelID
	and Housing_1.[UniqueID ] <> Housing_2.[UniqueID ]
Where Housing_1.PropertyAddress is null

--updating table with new field data
Update Housing_1
Set PropertyAddress = ISNULL(Housing_1.PropertyAddress, Housing_2.PropertyAddress)
From dbo.Nashville_Housing as Housing_1
join dbo.Nashville_Housing as Housing_2
	on Housing_1.ParcelID = Housing_2.ParcelID
	and Housing_1.[UniqueID ] <> Housing_2.[UniqueID ]
Where Housing_1.PropertyAddress is null


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--BREAKING ADDRESS field INTO SEPARATE ADDRESS, CITY AND STATE fieldS

--viewing property address field
Select PropertyAddress
From dbo.Nashville_Housing

--using SUBSTRING for splitting property address field data into new address and city
Select
	SUBSTRING(PropertyAddress,1,CHARINDEX(',', PropertyAddress) -1) as Address,
	SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) as City
From dbo.Nashville_Housing

--adding new address field 
Alter Table dbo.Nashville_Housing
Add PropertySplitAddress Nvarchar(255)

--populating new address field with substring data
Update dbo.Nashville_Housing
Set PropertySplitAddress = SUBSTRING(PropertyAddress,1,CHARINDEX(',', PropertyAddress) -1)

--adding new city field 
Alter Table dbo.Nashville_Housing
Add PropertySplitCity Nvarchar(255)

--populating new city field with substring data
Update dbo.Nashville_Housing
Set PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))

--viewing owner address field
Select OwnerAddress
From dbo.Nashville_Housing

--using PARSENAME for splitting owner address data into address, city and state
Select
	PARSENAME(REPLACE(OwnerAddress,',','.'), 3), /* since PARSENAME works only with delimiter '.', using nested function of REPLACE to convert ',' to '.' in the OwnerAddress data */
	PARSENAME(REPLACE(OwnerAddress,',','.'), 2),
	PARSENAME(REPLACE(OwnerAddress,',','.'), 1)
From dbo.Nashville_Housing

--adding new address field 
Alter Table dbo.Nashville_Housing
Add OwnerSplitAddress Nvarchar(255)

--populating new address field
Update dbo.Nashville_Housing
Set OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',','.'), 3)

--adding new city field 
Alter Table dbo.Nashville_Housing
Add OwnerSplitCity Nvarchar(255)

--populating new city field
Update dbo.Nashville_Housing
Set OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',','.'), 2)

--adding new state field 
Alter Table dbo.Nashville_Housing
Add OwnerSplitState Nvarchar(255)

--populating new state field
Update dbo.Nashville_Housing
Set OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',','.'), 1)


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- CHANGING Y AND N TO YES AND NO IN 'SOLD AS VACANT' FIELD

--viewing SoldAsVacant field
Select Distinct SoldAsVacant
From dbo.Nashville_Housing

--CASE statement use for changing Y and N to Yes and No
Select SoldAsVacant,
	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		 WHEN SoldAsVacant = 'N' THEN 'No'
		 ELSE SoldAsVacant
		 END
From dbo.Nashville_Housing

-- updating the change in SoldAsVacant field
Update Nashville_Housing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		 WHEN SoldAsVacant = 'N' THEN 'No'
		 ELSE SoldAsVacant
		 END


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/* Only for demo purpose, raw data is never to be deleted */

--REMOVING DUPLICATE ROWS 

--creating CTE with ROW_NUMBER function
WITH RowNumCTE AS
(Select*,
	   ROW_NUMBER() OVER(Partition by ParcelID,
									  PropertyAddress,
									  SalePrice,
									  SaleDate,
									  LegalReference
					      Order by UniqueID) AS RowNumber
From dbo.Nashville_Housing)

Select*
From RowNumCTE

--deleting duplicate rows
Delete
From RowNumCTE
Where RowNumber > 1

--viewing table to confirm if rows are deleted or not
Select*
From RowNumCTE
Where RowNumber > 1


--DELETING UNUSED COLUMNS

--identifying unused columns to delete
Select*
From dbo.Nashville_Housing

--deleting columns
Alter Table dbo.Nashville_Housing
Drop Column PropertyAddress, SaleDate, OwnerAddress, TaxDistrict

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------